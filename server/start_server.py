import server.server_init as server_init
import server.text_translate as tt
import server.gctts as tts
import server.tctts as tctts

import firebase_admin
from firebase_admin import firestore
from firebase_admin import storage

from fastapi import FastAPI, HTTPException, File, UploadFile, Form
from fastapi.responses import StreamingResponse, Response
from io import BytesIO

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from server.DTO.set_user_dto import UserDTO, SetRegionDTO
from server.DTO.trans_text_dto import TransTextDTO, TransTextReDTO
from server.DTO.get_tts_dto import GetTTSReqDTO, GetTTSAudioDTO
from server.DTO.user_practice_dto import SavePracticeDTO, UpdatePracticeDTO
from server.DTO.analysis_dto import AnalysisResult, VoiceAnalysisResponse, VoiceAnalysisResponse2
from server.DTO.login_dto import LoginHistoryResDTO

from server.analysis import *

from server.timestamp_cal import ts_cal

from datetime import datetime
import concurrent.futures
import gzip
import json
import zipfile

import os
import shutil

import whisperx

if not firebase_admin._apps:  # 이미 초기화된 앱이 없으면 초기화
    server_init.init_server()

SWAGGER_HEADERS = {
    "title": "ATOS API List",
    "version": "v593",
    "description": "## ATOS API \n - 2024년도 2학기 \n - 중앙대학교 캡스톤 디자인(1)\n - 사투리 억양 교정 앱 프로젝트",
    "contact": {
        "name": "ATOS",
        "email": "atoscd593@gmail.com",
    },
}

db = firestore.client()
app = FastAPI(swagger_ui_parameters={
        "deepLinking": True,
        "displayRequestDuration": True,
        "docExpansion": "list",
        "operationsSorter": "method",
        "filter": True,
        "tagsSorter": "alpha",
        "syntaxHighlight.theme": "solarized-dark",
    },
    **SWAGGER_HEADERS)
bucket = storage.bucket('atos-cd1.appspot.com')

# 디비
toTranslateText_db = db.collection('toTranslateText')
userAudio_db = db.collection('userAudio')
translatedText_db = db.collection('translatedText')
userData_db = db.collection('userData')
userConnection_db = db.collection('userConnection')
tempText_db = db.collection('tempText')
userPractice_db = db.collection('userPractice')

# class LogMiddleware(BaseHTTPMiddleware):
#     async def dispatch(self, request: Request, call_next):
#         body = await request.body()
#         print(f"Headers: {request.headers}")
#         print(f"Body: {body}")
#         response = await call_next(request)
#         return response

# app.add_middleware(LogMiddleware)

@app.on_event("startup")
async def startup_event():
    load_models()

@app.get('/login/{user_id}',description='로그인 기록 저장(로그인 후 호출하기)\n날짜별 하나만 저장 가능', tags=['User api'])
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

@app.get('/get-login-history/{user_id}',description='로그인 기록 조회', tags=['User api'], response_model=LoginHistoryResDTO)
async def get_login_history(user_id: str):
    try:
        query = userConnection_db.where('user_id', '==', user_id).stream()

        login_history = []

        for doc in query:
            login_history.append({**doc.to_dict()})

        if not login_history:
            raise HTTPException(status_code=404, detail="로그인 기록이 없습니다.")
        
        response = {
            'login_history': login_history,
            'login_count': len(login_history)
        }

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get('')

    

@app.post('/set-user-region',description='사용자 지역 정보 변경', tags=['User api'])
async def set_user_region(request: SetRegionDTO):
    try:
        user_ref = userData_db.document(request.user_id)
        user_ref.update({'region': request.region})

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/set-user',description='사용자 정보 저장', tags=['User api'])
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

@app.get('/get-user/{user_id}',description='사용자 정보 조회', tags=['User api'])
async def get_user(user_id: str):
    try:
        user = userData_db.document(user_id).get().to_dict()

        if not user:
            raise HTTPException(status_code=404, detail="사용자 정보가 없습니다.")
        
        return user
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post('/set-user-pitch',description='사용자 피치 저장', tags=['User api'])
async def set_user_pitch(low: UploadFile = File(...), high: UploadFile = File(...), user_id: str = Form(...)):
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)
        low_voice_path = os.path.join(upload_dir, low.filename)
        with open(low_voice_path, "wb") as buffer:
            shutil.copyfileobj(low.file, buffer)

        high_voice_path = os.path.join(upload_dir, high.filename)
        with open(high_voice_path, "wb") as buffer:
            shutil.copyfileobj(high.file, buffer)

        low_pitch = get_pitch_median(low_voice_path)
        high_pitch = get_pitch_median(high_voice_path)

        low_pitch = max(50, low_pitch)
        high_pitch = min(300, high_pitch)

        user_pitch_save_dto = {
            'low_pitch': int(low_pitch),
            'high_pitch': int(high_pitch)
        }

        user_pitch_ref = userData_db.document(user_id)
        user_pitch_ref.update(user_pitch_save_dto)

        os.remove(low_voice_path)
        os.remove(high_voice_path)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post('/set-user-low-pitch',description='사용자 피치 저장', tags=['User api'])
async def set_user_pitch(low: UploadFile = File(...), user_id: str = Form(...)):
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)
        low_voice_path = os.path.join(upload_dir, low.filename)
        with open(low_voice_path, "wb") as buffer:
            shutil.copyfileobj(low.file, buffer)

        low_pitch = get_pitch_median(low_voice_path)

        low_pitch = max(50, low_pitch)

        user_pitch_save_dto = {
            'low_pitch': int(low_pitch)
        }

        user_pitch_ref = userData_db.document(user_id)
        user_pitch_ref.update(user_pitch_save_dto)

        os.remove(low_voice_path)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/set-user-high-pitch',description='사용자 피치 저장', tags=['User api'])
async def set_user_pitch(high: UploadFile = File(...), user_id: str = Form(...)):
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)

        high_voice_path = os.path.join(upload_dir, high.filename)
        with open(high_voice_path, "wb") as buffer:
            shutil.copyfileobj(high.file, buffer)

        high_pitch = get_pitch_median(high_voice_path)

        high_pitch = min(300, high_pitch)

        user_pitch_save_dto = {
            'high_pitch': int(high_pitch)
        }

        user_pitch_ref = userData_db.document(user_id)
        user_pitch_ref.update(user_pitch_save_dto)

        os.remove(high_voice_path)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/translate-text',response_model=TransTextReDTO,description='텍스트 번역 후 tts 파일 생성', tags=['TTS api']) 
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
        audio = None
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
                  "description": "음성 파일 경로를 반환합니다.",
                  "content": {"audio/wav": {}}
                  }}, tags=['TTS api'])
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
        audio = None
        if request.theme == '성급한':
            audio = tts.getTTS(request.text, request.sex, speaking_rate=1.4)
        elif request.theme == '느긋한':
            audio = tts.getTTS(request.text, request.sex, speaking_rate=1.0)
        elif request.theme == '차분한':
            audio = tctts.getTCTTS(request.text)

        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        response = {
            "audio_title": audio_db_collection + translated_text_ref.id + audio_type
        }

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post('/get-tc-tts',description='타입캐스트 tts 생성', tags=['TTS api'])
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
    
@app.post("/get-tts-audio/", description="TTS 음성 파일 조회 (앱에서 쓸 필요 없음)", tags=['TTS api'])
async def get_tts_audio(request: GetTTSAudioDTO):
    try:
        blob = bucket.blob(request.audio_path)
        audio = blob.download_as_string()

        audio_stream = BytesIO(audio)
        audio_stream.seek(0)

        local_file_path = f"server/tts_audio/{request.audio_path.split('/')[-1]}"
        with open(local_file_path, "wb") as f:
            f.write(audio)
        
        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

    
@app.get("/get-user-practice/{user_id}", description="사용자의 연습 데이터 조회", tags=['Practice api'])
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
    
@app.get("/get-user-practice-data/{data_path}", description="사용자의 연습 데이터 상세 조회. userVoice, ttsVoice, analysis를 압축한 zip파일 리턴", tags=['Practice api'])
async def get_user_practice_data(data_path: str):
    try:
        blob = bucket.blob(data_path + 'userVoice.wav')
        blob2 = bucket.blob(data_path + 'ttsVoice.wav')
        blob3 = bucket.blob(data_path + 'analysis.json.gz')
        user_voice = blob.download_as_string()
        tts_voice = blob2.download_as_string()
        analysis_result = blob3.download_as_string()

        zip_buffer = BytesIO()
        with zipfile.ZipFile(zip_buffer, "w") as zip_file:
            zip_file.writestr("userVoice.wav", user_voice)
            zip_file.writestr("ttsVoice.wav", tts_voice)
            zip_file.writestr("analysis.json.gz", analysis_result)

        zip_buffer.seek(0)
        
        return StreamingResponse(zip_buffer, media_type="application/zip", headers={"Content-Disposition": f"attachment; filename={data_path}.zip"})

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post("/save-user-practice", description="사용자의 연습 데이터 저장", tags=['Practice api'])
async def save_user_practice(request: SavePracticeDTO):
    try:
        text = tempText_db.document(str(request.temp_id)).get().to_dict().get('text')
        first_audio = tempText_db.document(str(request.temp_id)).get().to_dict().get('first_audio')
        audio_db_collection = 'temp/' + str(request.temp_id) + '/'
        blob = bucket.blob(audio_db_collection + 'userVoice.wav')
        blob2 = bucket.blob(audio_db_collection + 'ttsVoice.wav')
        blob3 = bucket.blob(audio_db_collection + 'analysis.json')
        user_voice = blob.download_as_string()
        tts_voice = blob2.download_as_string()
        analysis_result = blob3.download_as_string()

        date = datetime.now()
        formatted_date = str(date.strftime("%Y%m%d%H%M%S"))

        practice_save_db = 'userPractice/'+str(request.user_id)+ formatted_date +'/'
        blob = bucket.blob(practice_save_db + 'userVoice.wav')
        blob.upload_from_string(user_voice, content_type="audio/wav")
        blob = bucket.blob(practice_save_db + 'ttsVoice.wav')
        blob.upload_from_string(tts_voice, content_type="audio/wav")
        blob = bucket.blob(practice_save_db + 'analysis.json')
        blob.upload_from_string(analysis_result, content_type="application/json")

        user_practice_save_dto = {
            'user_id': str(request.user_id),
            'title': str(request.title),
            'text': text,
            'date': str(date.date()),
            'data_path': practice_save_db,
            'first_audio': first_audio
        }

        userPractice_db.document().set(user_practice_save_dto)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post("/update-user-practice", description="사용자의 연습 데이터 수정", tags=['Practice api'])
async def update_user_practice(request: UpdatePracticeDTO):
    try:
        user_practice_ref = userPractice_db.where('title', '==', request.title).where('user_id', '==', request.user_id).stream()
        audio_db_collection = 'temp/' + str(request.temp_id) + '/'
        blob = bucket.blob(audio_db_collection + 'userVoice.wav')
        blob3 = bucket.blob(audio_db_collection + 'analysis.json')
        user_voice = blob.download_as_string()
        analysis_result = blob3.download_as_string()

        saved_date = user_practice_ref[0].to_dict().get('date')
        practice_date = user_practice_ref[0].to_dict().get('practice_date')

        date = datetime.now()
        practice_date.append(str(date.strftime("%Y%m%d%H%M%S")))

        practice_save_db = 'userPractice/'+str(request.user_id)+ saved_date +'/'
        blob = bucket.blob(practice_save_db + 'userVoice.wav')
        blob.upload_from_string(user_voice, content_type="audio/wav")
        blob = bucket.blob(practice_save_db + 'analysis.json')
        blob.upload_from_string(analysis_result, content_type="application/json")

        save_title = request.title

        if request.changed_title:
            save_title = request.changed_title


        user_practice_save_dto = {
            'title': save_title,
            'practice_date': practice_date,
        }

        for doc in user_practice_ref:
            userPractice_db.document(doc.id).update(user_practice_save_dto)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-analysis-data/{data_path}", description="temp에서 사용자의 분석 데이터 return. 분석 결과를 압축한 gzip파일 리턴", tags=['Analysis api'])
async def get_analysis_data(data_path: str):
    try:
        
        blob3 = bucket.blob('temp/' + data_path + '/analysis.json')
        analysis_result = blob3.download_as_string()

        return Response(content=analysis_result, media_type="application/json")
        #return StreamingResponse(iterfile(), media_type="application/gzip", headers={"Content-Encoding": "gzip"})
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post("/voice-analysis",description="음성 분석\n사용자음성, tts음성, 텍스트를 받아 분석 후 결과 반환", tags=['Analysis api'], response_model=VoiceAnalysisResponse2)
async def voice_analysis(user_voice: UploadFile = File(...), tts_voice: UploadFile = File(...), text: str = Form(...), user_id: str = Form(...)):
    try :
        temp_save_id = user_id + str(datetime.now().strftime("%Y%m%d%H%M%S"))
        upload_dir = "server/filtered_audio"
        temp_db_collection = 'temp/'+temp_save_id+'/'
        os.makedirs(upload_dir, exist_ok=True)

        first_audio_db_collection = 'FirstUserVoice/' + user_voice.filename
        # 텍스트 임시 저장
        text_save_dto = {
            'user_id': user_id,
            'text': text,
            'first_audio': first_audio_db_collection
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

        user_doc = userData_db.document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User not found")

        user_data = user_doc.to_dict()
        low = min(user_data.get('low_pitch'),user_data.get('high_pitch'))
        high = max(user_data.get('low_pitch'),user_data.get('high_pitch'))

        sampling_rate, filtered_data, pitch_values, time_steps = process_and_save_filtered_audio(input_file_path=user_voice_path, human_voice_range=(low-10, high+10))

        with open(user_voice_path, "rb") as audio_file:
            audio = audio_file.read()

        blob = bucket.blob(first_audio_db_collection)
        blob.upload_from_string(audio, content_type="audio/wav")

        tts_sampling_rate, tts_data, pitch_values_tts, time_steps_tts = extract_pitch_from_tts(tts_voice_path)

        word_intervals = cal_timestamp(extract_word_timestamps(user_voice_path))
        tts_word_intervals = extract_word_timestamps(tts_voice_path)

        with concurrent.futures.ThreadPoolExecutor() as executor:
            future_word_intervals = executor.submit(ts_cal, word_intervals, text)
            future_tts_word_intervals = executor.submit(ts_cal, tts_word_intervals, text)

            word_intervals = future_word_intervals.result()
            tts_word_intervals = future_tts_word_intervals.result()

        threshold_value = 5600
        comp_amp_result, max_word = compare_amplitude_differences(word_intervals, tts_word_intervals, filtered_data, tts_data, tts_sampling_rate, sampling_rate, threshold_value)

        comp_pitch_result = calculate_pitch_differences(
        word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts)

        # 세그먼트 비교
        # highest_segment, lowest_segment = compare_segments(
        #     word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts
        # )

        results = compare_pitch_differences(word_intervals, pitch_values, tts_word_intervals, pitch_values_tts,time_steps,time_steps_tts, threshold=20)
     
        # 파일 삭제
        os.remove(user_voice_path)
        os.remove(tts_voice_path)

        result = {
            'word_intervals': word_intervals,
            'tts_word_intervals': tts_word_intervals,
            'comp_amp_result': comp_amp_result,
            'max_word': max_word,
            'comp_pitch_result': comp_pitch_result,
            #'highest_segment': highest_segment,
            #'lowest_segment': lowest_segment,
            'tts_data': tts_data.tolist(),
            'filtered_data': filtered_data.tolist(),
            'sampling_rate': sampling_rate,
            'tts_sampling_rate': tts_sampling_rate,
            'pitch_values': pitch_values.tolist(),
            'time_steps': time_steps.tolist(),
            'pitch_values_tts': pitch_values_tts.tolist(),
            'time_steps_tts': time_steps_tts.tolist(),
            'results': results
        }

        # gzip_buffer = BytesIO()
        # with gzip.GzipFile(fileobj=gzip_buffer, mode='w') as f:
        #     f.write(json.dumps(result).encode('utf-8'))
        json_str = json.dumps(result)
        # Gzip 파일을 Firebase Storage에 업로드
        # gzip_buffer.seek(0)
        blob = bucket.blob(f"{temp_db_collection}analysis.json")
        blob.upload_from_string(json_str, content_type="application/json")

        response = {
            'temp_id': temp_save_id
        }
        # def iterfile():
        #     gzip_buffer.seek(0)
        #     yield from gzip_buffer
        # StreamingResponse(iterfile(), media_type="application/gzip", headers={"Content-Encoding": "gzip"})
        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")


