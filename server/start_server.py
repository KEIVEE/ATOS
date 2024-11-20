import server.server_init as server_init
import server.text_translate as tt
import server.gctts as tts
import server.tctts as tctts

import firebase_admin
from firebase_admin import firestore
from firebase_admin import storage

from fastapi import FastAPI, HTTPException, File, UploadFile, Form
from fastapi.responses import StreamingResponse
from io import BytesIO

from server.DTO.set_user_dto import UserDTO
from server.DTO.trans_text_dto import TransTextDTO, TransTextReDTO
from server.DTO.get_tts_dto import GetTTSReqDTO
from server.DTO.user_practice_dto import SavePracticeDTO

from server.analysis import *

from server.timestamp_cal import ts_cal

from datetime import datetime

import os
import shutil

import whisperx

if not firebase_admin._apps:  # 이미 초기화된 앱이 없으면 초기화
    server_init.init_server()

db = firestore.client()
app = FastAPI()
bucket = storage.bucket('atos-cd1.appspot.com')
audio_blob_name = 'test_audio/'

# 디비
toTranslateText_db = db.collection('toTranslateText')
userAudio_db = db.collection('userAudio')
translatedText_db = db.collection('translatedText')
userData_db = db.collection('userData')
userConnection_db = db.collection('userConnection')
tempText_db = db.collection('tempText')
userPractice_db = db.collection('userPractice')

@app.on_event("startup")
async def startup_event():
    load_models()

@app.get('/')
def read_root():
    return 'Server for ATOS project'

@app.get('/login/{user_id}',description='로그인 기록 저장(로그인 후 호출하기)\n날짜별 하나만 저장 가능')
async def login(user_id: str): 
    try:
        login_date = str(datetime.now().date())
        connection_save_dto = {
            'user_id': user_id,
            'login_date': login_date
        }

        query = userConnection_db.where('user_id', '==', user_id).where('login_date', '==', login_date).stream()
        existing_docs = [doc for doc in query]

        if len(existing_docs) == 0 :
            userConnection_db.document().set(connection_save_dto)
            return True
        
        return False

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.get('/get-login-history/{user_id}',description='로그인 기록 조회')
async def get_login_history(user_id: str):
    try:
        query = userConnection_db.where('user_id', '==', user_id).stream()

        login_history = []

        for doc in query:
            login_history.append({**doc.to_dict()})

        if not login_history:
            raise HTTPException(status_code=404, detail="로그인 기록이 없습니다.")

        return login_history

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/set-user',description='사용자 정보 저장')
async def set_user(request: UserDTO):
    try:
        user_save_dto = {
            'user_id': request.user_id,
            'region': request.region,
            'sex': request.sex
        }

        user_ref = userData_db.document(request.user_id)
        user_ref.set(user_save_dto)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.get('/get-user/{user_id}',description='사용자 정보 조회')
async def get_user(user_id: str):
    try:
        user = userData_db.document(user_id).get().to_dict()

        if not user:
            raise HTTPException(status_code=404, detail="사용자 정보가 없습니다.")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/translate-text',response_model=TransTextReDTO,description='텍스트 번역 후 tts 파일 생성') 
async def translate_text(request: TransTextDTO):
    try:
        text_save_dto = {
            'text': request.text,
            'user_id': request.user_id,
            'region': request.region
        }
        text_ref = toTranslateText_db.document()
        text_ref.set(text_save_dto)

        translated_text = tt.gpt_translate(request.region,request.text)
        trans_text_save_dto = {
            'user_id': request.user_id,
            'text': translated_text
        }
        translated_text_ref = translatedText_db.document()
        translated_text_ref.set(trans_text_save_dto)

        audio_db_collection = 'gcTTS/'
        audio_type = '.wav'
        audio
        if request.theme == '성급한':
            audio = tts.getTTS(translated_text, request.sex, speaking_rate=1.4)
        elif request.theme == '느긋한':
            audio = tts.getTTS(translated_text, request.sex, speaking_rate=1.0)
        elif request.theme == '차분한':
            audio = tctts.getTCTTS(translated_text)
        
        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        response_dto = response_dto = TransTextReDTO(
            text_id=text_ref.id,
            text_data=text_save_dto.get('text'),
            translated_text_id=translated_text_ref.id,
            translated_text_data=trans_text_save_dto.get('text'),
            audio_title=audio_db_collection + translated_text_ref.id + audio_type
        )

        return response_dto

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post("/get-tts", description="번역하지 않고 tts만 생성.",
          responses={
              200: {
                  "description": "음성 파일을 반환합니다.",
                  "content": {"audio/wav": {}}
                  }})
async def get_tts(request: GetTTSReqDTO): 
    try:
        trans_text_save_dto = {
            'user_id': request.user_id,
            'text': request.text
        }
        translated_text_ref = translatedText_db.document()
        translated_text_ref.set(trans_text_save_dto)

        audio_db_collection = 'gcTTS/'
        audio_type = '.wav'
        audio
        if request.theme == '성급한':
            audio = tts.getTTS(request.text, request.sex, speaking_rate=1.4)
        elif request.theme == '느긋한':
            audio = tts.getTTS(request.text, request.sex, speaking_rate=1.0)
        elif request.theme == '차분한':
            audio = tctts.getTCTTS(request.text)
            
        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        return audio_db_collection + translated_text_ref.id + audio_type

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post('/get-tc-tts',description='타입캐스트 tts 생성')
async def get_tc_tts(request: GetTTSReqDTO):
    try:
        trans_text_save_dto = {
            'user_id': request.user_id,
            'text': request.text
        }
        translated_text_ref = translatedText_db.document()
        translated_text_ref.set(trans_text_save_dto)

        audio_db_collection = 'tcTTS/'
        audio_type = '.wav'
        audio = tctts.getTCTTS(request.text)
        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        audio_stream = BytesIO(audio)
        audio_stream.seek(0)

        return audio_db_collection + translated_text_ref.id + audio_type
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-tts-audio/{audio_id}", description="TTS 음성 파일 조회")
async def get_tts_audio(audio_id: str):
    try:
        audio_db_collection = 'tcTTS/'
        audio_type = '.wav'
        blob = bucket.blob(audio_db_collection + audio_id + audio_type)
        audio = blob.download_as_string()

        audio_stream = BytesIO(audio)
        audio_stream.seek(0)

        local_file_path = f"server/tts_audio/{audio_id}{audio_type}"
        with open(local_file_path, "wb") as f:
            f.write(audio)

        return StreamingResponse(audio_stream, media_type="audio/wav")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

    
@app.get("/get-user-practice/{user_id}", description="사용자의 연습 데이터 조회")
async def get_user_practice(user_id : str) :
    try:
        query = userPractice_db.where("user_id", "==", user_id).stream()

        practices = []
        
        for doc in query:
            practices.append({**doc.to_dict(), 'doc_id': doc.id})

        if not practices:
            raise HTTPException(status_code=404, detail="사용자의 연습 데이터가 없습니다.")
        
        return practices
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post("/save-user-practice", description="사용자의 연습 데이터 저장")
async def save_user_practice(request: SavePracticeDTO):
    try:
        text = tempText_db.document(request.temp_id).get().to_dict().get('text')
        audio_db_collection = 'temp/' + request.temp_id + '/'
        blob = bucket.blob(audio_db_collection + 'userVoice.wav')
        blob2 = bucket.blob(audio_db_collection + 'ttsVoice.wav')
        user_voice = blob.download_as_string()
        tts_voice = blob2.download_as_string()

        date = datetime.now()
        formatted_date = str(date.strftime("%Y%m%d%H%M%S"))

        practice_save_db = 'userPractice/'+request.user_id+ formatted_date +'/'
        blob = bucket.blob(practice_save_db + 'userVoice.wav')
        blob.upload_from_string(user_voice, content_type="audio/wav")
        blob = bucket.blob(practice_save_db + 'ttsVoice.wav')
        blob.upload_from_string(tts_voice, content_type="audio/wav")

        user_practice_save_dto = {
            'user_id': request.user_id,
            'title': request.title,
            'description': request.description,
            'text': text,
            'date': str(date.date()),
            'voice_path': practice_save_db
        }

        userPractice_db.document().set(user_practice_save_dto)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")


@app.post("/voice-analysis",description="음성 분석\n사용자음성, tts음성, 텍스트를 받아 분석 후 결과 반환")
async def voice_analysis(user_voice: UploadFile = File(...), tts_voice: UploadFile = File(...), text: str = Form(...), user_id: str = Form(...)):
    try :
        temp_save_id = user_id + str(datetime.now().strftime("%Y%m%d%H%M%S"))
        upload_dir = "server/filtered_audio"
        temp_db_collection = 'temp/'+temp_save_id+'/'
        os.makedirs(upload_dir, exist_ok=True)

        # 텍스트 임시 저장
        text_save_dto = {
            'user_id': user_id,
            'text': text
        }
        temp_text_ref = tempText_db.document(temp_save_id)
        temp_text_ref.set(text_save_dto)

        # user_voice 파일 저장
        user_voice_path = os.path.join(upload_dir, user_voice.filename)
        with open(user_voice_path, "wb") as buffer:
            shutil.copyfileobj(user_voice.file, buffer)

        with open(user_voice_path, "rb") as audio_file:
            audio = audio_file.read()
        
        blob = bucket.blob(temp_db_collection + 'userVoice.wav')
        blob.upload_from_string(audio, content_type="audio/wav")

        # tts_voice 파일 저장
        tts_voice_path = os.path.join(upload_dir, tts_voice.filename)
        with open(tts_voice_path, "wb") as buffer:
            shutil.copyfileobj(tts_voice.file, buffer)

        with open(tts_voice_path, "rb") as audio_file:
            tts_audio = audio_file.read()

        blob = bucket.blob(temp_db_collection + 'ttsVoice.wav')
        blob.upload_from_string(tts_audio, content_type="audio/wav")

        sampling_rate, filtered_data, pitch_values, time_steps = process_and_save_filtered_audio(input_file_path=user_voice_path)

        with open(user_voice_path, "rb") as audio_file:
            audio = audio_file.read()

        audio_db_collection = 'filteredUserVoice/'
        blob = bucket.blob(audio_db_collection + user_voice.filename)
        blob.upload_from_string(audio, content_type="audio/wav")

        tts_sampling_rate, tts_data, pitch_values_tts, time_steps_tts = extract_pitch_from_tts(tts_voice_path)

        word_intervals = cal_timestamp(extract_word_timestamps(user_voice_path))
        tts_word_intervals = extract_word_timestamps(tts_voice_path)
        print("=============타임스탬프 추출 완료=============")

        word_intervals = ts_cal(word_intervals, text)
        tts_word_intervals = ts_cal(tts_word_intervals, text)
        print("=============타임스탬프 보정 완료=============")

        threshold_value = 5600
        user_exceeding_words, tts_exceeding_words, max_word = compare_amplitude_differences(word_intervals, tts_word_intervals, filtered_data, tts_data, tts_sampling_rate, sampling_rate, threshold_value)

        print("=================================================================================")
        print("user_exceeding_words : ")
        print(user_exceeding_words)
        print("=================================================================================")
        print("tts_exceeding_words : ")
        print(tts_exceeding_words)
        print("=================================================================================")
        print("max_word : ")
        print(max_word)
        print("=================================================================================\n\n\n")

        u_results,t_results = calculate_pitch_differences(
        word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts)

        print("=================================================================================")
        print("u_results : ")
        print(u_results)
        print("=================================================================================")
        print("t_results : ")
        print(t_results)
        print("=================================================================================\n\n\n")

        # 세그먼트 비교
        highest_segment, lowest_segment = compare_segments(
            word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts
        )

        print("=================================================================================")
        print("highest_segment : ")
        print(highest_segment)
        print("=================================================================================")
        print("lowest_segment : ")
        print(lowest_segment)

        # 파일 삭제
        os.remove(user_voice_path)
        os.remove(tts_voice_path)

        result = '성공'

        # result 구성 요소
        # 1. 보정된 timestamp (json 형식)
        # 2. 사용자 음성과 TTS 음성의 세기 차이가 큰 단어 (json 형식)
        # 3. temp_save_id (string) ==> 나중에 저장 시 사용
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")


