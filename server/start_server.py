import server.server_init as server_init
import server.text_translate as tt
import server.gctts as tts

import tempfile

import firebase_admin
from firebase_admin import firestore
from firebase_admin import storage

from fastapi import FastAPI, Request, HTTPException, File, UploadFile, Form
from fastapi.responses import StreamingResponse
from io import BytesIO

from server.DTO.set_user_dto import UserDTO
from server.DTO.trans_text_dto import TransTextDTO, TransTextReDTO

from server.analysis.get_timestamp import extract_word_timestamps, load_models

from server.analysis import *

from server.timestamp_cal import ts_cal

import os
import shutil

import whisperx

init_call_os_text = True  # 처음에는 True로 설정
init_call_os_audio = True 

if not firebase_admin._apps:  # 이미 초기화된 앱이 없으면 초기화
    server_init.init_server()

print('서버 시작')

db = firestore.client()
app = FastAPI()
bucket = storage.bucket('atos-cd1.appspot.com')
audio_blob_name = 'test_audio/'

# 디비
toTranslateText_db = db.collection('toTranslateText')
userAudio_db = db.collection('userAudio')
translatedText_db = db.collection('translatedText')
userData_db = db.collection('userData')

@app.on_event("startup")
async def startup_event():
    load_models()

@app.get('/')
def read_root():
    return 'Server for ATOS project'

@app.post('/set-user')
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


@app.post('/translate-text',response_model=TransTextReDTO) 
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
        audio = tts.getTTS(translated_text)
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
    
@app.post("/get-tts")
async def get_tts(request: Request) :
    try:
        body = request.json()

        translated_text = body.get('text')
        trans_text_save_dto = {
            'user_id': body.get('user_id'),
            'text': translated_text
        }
        translated_text_ref = translatedText_db.document()
        translated_text_ref.set(trans_text_save_dto)

        audio_db_collection = 'gcTTS/'
        audio_type = '.wav'
        audio = tts.getTTS(translated_text)
        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        audio_stream = BytesIO(audio)
        audio_stream.seek(0)

        return StreamingResponse(audio_stream, media_type="audio/wav")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-user-practice/{user_id}")
async def get_user_practice(user_id : str) :
    try:
        query = translatedText_db.where("user_id", "==", user_id).stream()

        translated_texts = []
        
        for doc in query:
            translated_texts.append({**doc.to_dict(), 'id': doc.id})

        if not translated_texts:
            raise HTTPException(status_code=404, detail="사용자의 연습 데이터가 없습니다.")
        
        return {"translated_texts": translated_texts}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")


@app.post("/voice-analysis")
async def voice_analysis(user_voice: UploadFile = File(...), tts_voice: UploadFile = File(...), text: str = Form(...)):
    try :
        upload_dir = "server/filtered_audio"
        os.makedirs(upload_dir, exist_ok=True)

        # user_voice 파일 저장
        user_voice_path = os.path.join(upload_dir, user_voice.filename)
        with open(user_voice_path, "wb") as buffer:
            shutil.copyfileobj(user_voice.file, buffer)

        with open(user_voice_path, "rb") as audio_file:
            audio = audio_file.read()

        audio_db_collection = 'userVoice/'
        blob = bucket.blob(audio_db_collection + user_voice.filename)
        blob.upload_from_string(audio, content_type="audio/wav")

        # tts_voice 파일 저장
        tts_voice_path = os.path.join(upload_dir, tts_voice.filename)
        with open(tts_voice_path, "wb") as buffer:
            shutil.copyfileobj(tts_voice.file, buffer)

        with open(tts_voice_path, "rb") as audio_file:
            tts_audio = audio_file.read()

        # Firebase Storage에 업로드
        tts_audio_db_collection = 'ttsVoice/'
        blob = bucket.blob(tts_audio_db_collection + tts_voice.filename)
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

        # for word_info in user_exceeding_words:
        #     print(f"단어: {word_info['word']}이(가) 표준어 대비 세기 차이가 강해요")

        # for word_info in tts_exceeding_words:
        #     print(f"단어: {word_info['word']}이(가) 표준어 대비 세기 차이가 약해요")

        # print(f"단어: {max_word['word']}이(가) 너무 세게 말해요.")

        u_results,t_results = calculate_pitch_differences(
        word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts)

        print("=================================================================================")
        print("u_results : ")
        print(u_results)
        print("=================================================================================")
        print("t_results : ")
        print(t_results)
        print("=================================================================================\n\n\n")
        # for word_info in u_results:
        #     print(f"단어: {word_info['word']}이(가) 표준어 대비 억양 차이가 심해요")
        # for word_info in t_results:
        #     print(f"단어: {word_info['word']}이(가) 표준어 대비 억양 차이가 약해요")

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

        # 결과 출력
        # if highest_segment:
        #     user_segment_high, tts_segment_high, avg_user_gradient_high, avg_tts_gradient_high = highest_segment
        #     print(f"음성이 TTS 대비 가장 높은 기울기를 가진 세그먼트:")
        #     print(f"사용자 세그먼트: {user_segment_high}, TTS 세그먼트: {tts_segment_high}")
        #     print(f"사용자 평균 기울기: {avg_user_gradient_high:.4f}, TTS 평균 기울기: {avg_tts_gradient_high:.4f}")
        #     print("음성이 TTS 대비 기울기가 높아요.")

        # if lowest_segment:
        #     user_segment_low, tts_segment_low, avg_user_gradient_low, avg_tts_gradient_low = lowest_segment
        #     print(f"음성이 TTS 대비 가장 낮은 기울기를 가진 세그먼트:")
        #     print(f"사용자 세그먼트: {user_segment_low}, TTS 세그먼트: {tts_segment_low}")
        #     print(f"사용자 평균 기울기: {avg_user_gradient_low:.4f}, TTS 평균 기울기: {avg_tts_gradient_low:.4f}")
        #     print("음성이 TTS 대비 기울기가 낮아요.")
        # else:
        #     print("세그먼트 비교에서 차이를 찾을 수 없습니다.")

        # 파일 삭제
        os.remove(user_voice_path)
        os.remove(tts_voice_path)

        result = '성공'

        # result 구성 요소
        # 1. 보정된 timestamp (json 형식)
        # 2. 사용자 음성과 TTS 음성의 세기 차이가 큰 단어 (json 형식)
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")


