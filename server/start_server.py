import server.server_init as server_init
import server.text_translate as tt
import server.gctts as tts
import server.tctts as tctts

import firebase_admin
from firebase_admin import firestore, storage, auth, credentials

from fastapi import FastAPI, HTTPException, File, UploadFile, Form, Request, Depends
from fastapi.responses import StreamingResponse, Response, JSONResponse
from io import BytesIO

from server.DTO.set_user_dto import *
from server.DTO.trans_text_dto import *
from server.DTO.get_tts_dto import *
from server.DTO.user_practice_dto import *
from server.DTO.analysis_dto import *
from server.DTO.login_dto import *

from server.analysis import *

from server.timestamp_cal import ts_cal

from datetime import datetime, timedelta
import concurrent.futures
import gzip
import json
import zipfile

import os
import shutil
from concurrent.futures import ThreadPoolExecutor


import whisperx

if not firebase_admin._apps:  # 이미 초기화된 앱이 없으면 초기화
    server_init.init_server()

# swagger ui 설정
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
todaySentence_db = db.collection('todaySentence')

# class LogMiddleware(BaseHTTPMiddleware):
#     async def dispatch(self, request: Request, call_next):
#         body = await request.body()
#         print(f"Headers: {request.headers}")
#         print(f"Body: {body}")
#         response = await call_next(request)
#         return response

# app.add_middleware(LogMiddleware)

def verify_token(request: Request):
    id_token = request.headers.get('Authorization')
    if not id_token:
        raise HTTPException(status_code=402, detail="Missing id_token")

    if id_token.startswith("Bearer "):
        id_token = id_token.split(" ")[1]

    try:
        decoded_token = auth.verify_id_token(id_token)
        email = decoded_token['email']
        user_id = email.split('@')[0]
        return user_id
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token verification failed: {str(e)}")

@app.on_event("startup")
async def startup_event():
    load_models() # 시작할 때 whisperx 모델 로드 후 저장

@app.get('/login/{user_id}',description='로그인 기록 저장(로그인 후 호출하기)\n날짜별 하나만 저장 가능', tags=['User api'])
async def login(user_id: str, verified_user_id: str = Depends(verify_token)): 
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")

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
async def get_login_history(user_id: str, verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid user_id")
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
    
@app.get('/get-green-graph/{user_id}',description='사용자의 일주일간 잔디심기 기록 리턴', tags=['User api'])
async def get_green_graph(user_id: str, verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        query = userConnection_db.where('user_id', '==', user_id).stream()

        today = datetime.now().date()

        green_graph = [0] * 7  
        week_date = [(today-timedelta(days=i)).strftime("%m-%d") for i in range(7)]
        week_date.reverse()

        for doc in query:
            login_date_str = doc.to_dict().get('login_date')
            login_date = datetime.strptime(login_date_str, "%Y-%m-%d").date()
            date_diff = (today - login_date).days
            if date_diff < 7:
                green_graph[6 - date_diff] = 1

        num = sum(green_graph)

        dto = {
            'data': {
                'green_graph': green_graph,
                'week_dates' : week_date,
                'num': str(num)
            }
        }

        return dto

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

    

@app.post('/set-user-region',description='사용자 지역 정보 변경', tags=['User api'])
async def set_user_region(request: SetRegionDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        user_ref = userData_db.document(request.user_id)
        user_ref.update({'region': request.region})

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post('/set-user',description='사용자 정보 저장', tags=['User api'])
async def set_user(request: UserDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        user_save_dto = {
            'user_id': request.user_id,
            'region': request.region,
            'sex': request.sex,
            'low_pitch': 50,
            'high_pitch': 300
        }

        user_ref = userData_db.document(request.user_id)
        user_ref.set(user_save_dto)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.get('/get-user/{user_id}',description='사용자 정보 조회', tags=['User api'])
async def get_user(user_id: str, verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        user = userData_db.document(user_id).get().to_dict()

        if not user:
            return Response(status_code=204, content="사용자 정보가 없습니다.")
        
        return user
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.post('/set-user-pitch',description='사용자 피치 저장', tags=['User api'])
async def set_user_pitch(low: UploadFile = File(...), high: UploadFile = File(...), user_id: str = Form(...), verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)
        low_voice_path = os.path.join(upload_dir, 'low'+low.filename)
        with open(low_voice_path, "wb") as buffer:
            shutil.copyfileobj(low.file, buffer)

        high_voice_path = os.path.join(upload_dir, 'high'+high.filename)
        with open(high_voice_path, "wb") as buffer:
            shutil.copyfileobj(high.file, buffer)

        low_pitch = get_pitch_median(low_voice_path)
        high_pitch = get_pitch_median(high_voice_path)

        low_pitch = max(50, low_pitch) # 목소리 임계값 설정
        low_pitch = min(90, low_pitch)
        high_pitch = min(400, high_pitch)
        high_pitch = max(250, high_pitch)

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
async def set_user_pitch(low: UploadFile = File(...), user_id: str = Form(...), verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)
        low_voice_path = os.path.join(upload_dir, low.filename)
        with open(low_voice_path, "wb") as buffer:
            shutil.copyfileobj(low.file, buffer)

        low_pitch = get_pitch_median(low_voice_path)

        low_pitch = max(50, low_pitch)
        low_pitch = min(90, low_pitch)

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
async def set_user_pitch(high: UploadFile = File(...), user_id: str = Form(...), verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        upload_dir = "server/pitch_audio"
        os.makedirs(upload_dir, exist_ok=True)

        high_voice_path = os.path.join(upload_dir, high.filename)
        with open(high_voice_path, "wb") as buffer:
            shutil.copyfileobj(high.file, buffer)

        high_pitch = get_pitch_median(high_voice_path)

        high_pitch = min(400, high_pitch)
        high_pitch = max(250, high_pitch)

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
async def translate_text(request: TransTextDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    # 텍스트 번역 후 테마에 맞추어 TTS 생성
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
        if request.theme == '아나운서':
            audio = tctts.getTCTTS(translated_text,1)
        elif request.theme == '일상생활':
            audio = tctts.getTCTTS(translated_text,2)
        elif request.theme == '발표':
            audio = tctts.getTCTTS(translated_text,3)
        else :
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
async def get_tts(request: GetTTSReqDTO, verified_user_id: str = Depends(verify_token)): 
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    # 텍스트 번역을 하지 않고 바로 TTS 생성
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
        if request.theme == '아나운서':
            audio = tctts.getTCTTS(request.text,1)
        elif request.theme == '일상생활':
            audio = tctts.getTCTTS(request.text,2)
        elif request.theme == '발표':
            audio = tctts.getTCTTS(request.text,3)
        else :
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
async def get_tc_tts(request: GetTTSReqDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
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
async def get_tts_audio(request: GetTTSAudioDTO, verified_user_id: str = Depends(verify_token)):
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
async def get_user_practice(user_id : str, verified_user_id: str = Depends(verify_token)) :
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        query = userPractice_db.where("user_id", "==", user_id).stream()

        practices = []
        
        for doc in query:
            practices.append({**doc.to_dict(), 'doc_id': doc.id})

        if not practices:
            return Response(status_code=204, content="연습 데이터가 없습니다.")
        
        practices.sort(key=lambda x: datetime.strptime(x['detail_date'], "%Y-%m-%d %H:%M:%S.%f"), reverse=True)

        return practices
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-user-practice-recent/{user_id}", description="사용자의 최근 연습 데이터 조회", tags=['Practice api'])
async def get_user_practice_recent(user_id : str, verified_user_id: str = Depends(verify_token)) :
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        query = userPractice_db.where("user_id", "==", user_id).stream()

        practices = []
        
        for doc in query:
            practices.append({**doc.to_dict(), 'doc_id': doc.id})

        if not practices:
            return Response(status_code=204, content="연습 데이터가 없습니다.")
        
        practices.sort(key=lambda x: datetime.strptime(x['detail_date'], "%Y-%m-%d %H:%M:%S.%f"), reverse=True)
        return practices[0]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-user-practice-num/{user_id}", description="사용자의 연습 데이터 개수 조회", tags=['Practice api'])
async def get_user_practice_num(user_id : str, verified_user_id: str = Depends(verify_token)) :
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        query = userPractice_db.where("user_id", "==", user_id).stream()

        num = len([doc for doc in query])
        return num
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-user-practice-data/{data_path}", description="사용자의 연습 데이터 상세 조회. userVoice, ttsVoice, analysis를 압축한 zip파일 리턴", tags=['Practice api'])
async def get_user_practice_data(data_path: str, verified_user_id: str = Depends(verify_token)):
    # 사용자의 연습 기록을 반환 (플러터에서 ZIP 파일 해제에 문제가 있어 일단 보류)
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
async def save_user_practice(request: SavePracticeDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    # Temp 디비에 있는 데이터들을 userPractice 디비로 이동 (정식적으로 저장)
    # Temp 디비에 있는 데이터 삭제는 안함
    try:
        user_practice_ref = userPractice_db.where('title', '==', request.title).where('user_id', '==', request.user_id).stream()
        user_practice_ref = list(user_practice_ref)
        if user_practice_ref:
            audio_db_collection = 'temp/' + request.temp_id + '/'
            blob = bucket.blob(audio_db_collection + 'userVoice.wav')
            blob3 = bucket.blob(audio_db_collection + 'analysis.json')
            user_voice = blob.download_as_string()
            analysis_result = blob3.download_as_string()

            saved_date = user_practice_ref[0].to_dict().get('date')

            practice_save_db = 'userPractice/'+str(request.user_id)+ saved_date +'/'
            blob = bucket.blob(practice_save_db + 'userVoice.wav')
            blob.upload_from_string(user_voice, content_type="audio/wav")
            blob = bucket.blob(practice_save_db + 'analysis.json')
            blob.upload_from_string(analysis_result, content_type="application/json")

            date = datetime.now()
            user_practice_save_dto = {
                'date': str(date.date()),
                'detail_date': str(date)
            }

            userPractice_db.document(user_practice_ref[0].id).update(user_practice_save_dto)

            return True


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
            'detail_date': str(date),
            'data_path': practice_save_db,
            'first_audio': first_audio
        }

        userPractice_db.document().set(user_practice_save_dto)

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post("/update-user-practice", description="사용자의 연습 데이터 수정", tags=['Practice api'])
async def update_user_practice(request: UpdatePracticeDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
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
    
@app.delete("/delete-user-practice", description="사용자의 연습 데이터 삭제", tags=['Practice api'])
async def delete_user_practice(request: DeletePracticeDTO, verified_user_id: str = Depends(verify_token)):
    if request.user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    try:
        user_practice_ref = userPractice_db.where('title', '==', request.title).where('user_id', '==', request.user_id).stream()
        data_path = user_practice_ref[0].to_dict().get('data_path')

        for doc in user_practice_ref:
            userPractice_db.document(doc.id).delete()

        blob = bucket.blob(data_path + 'userVoice.wav')
        blob2 = bucket.blob(data_path + 'ttsVoice.wav')
        blob3 = bucket.blob(data_path + 'analysis.json')
        blob.delete()
        blob2.delete()
        blob3.delete()

        return True

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")
    
@app.get("/get-analysis-data/{data_path}", description="temp에서 사용자의 분석 데이터 return. 분석 결과를 json 파일로 리턴", tags=['Analysis api'])
async def get_analysis_data(data_path: str, verified_user_id: str = Depends(verify_token)):
    try:
        
        blob3 = bucket.blob('temp/' + data_path + '/analysis.json')
        analysis_result = blob3.download_as_string()

        return Response(content=analysis_result, media_type="application/json")
        #return StreamingResponse(iterfile(), media_type="application/gzip", headers={"Content-Encoding": "gzip"})
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post("/voice-analysis",description="음성 분석\n사용자음성, tts음성, 텍스트를 받아 분석 후 결과 반환", tags=['Analysis api'], response_model=VoiceAnalysisResponse2)
async def voice_analysis(user_voice: UploadFile = File(...), tts_voice: UploadFile = File(...), text: str = Form(...), user_id: str = Form(...), verified_user_id: str = Depends(verify_token)):
    if user_id != verified_user_id:
        raise HTTPException(status_code=401, detail="Invalid Token")
    # 사용자 음성, TTS 음성, 분석 결과는 Temp(임시 디비)에 저장됨
    # 나중에 사용자가 저장한다고 하면 Temp -> userPractice로 데이터 이동
    # 첫 음성 파일이 있다면 저장하지 않도록 하는 기능도 추가하기 (아니면 api 새로 만들어도 될듯)
    # TTS, 사용자 음성 비교 할 때 사용할 threshold 값 정하기
    try :
        temp_save_id = user_id + str(datetime.now().strftime("%Y%m%d%H%M%S"))
        upload_dir = "server/filtered_audio"
        temp_db_collection = 'temp/'+temp_save_id+'/'
        os.makedirs(upload_dir, exist_ok=True)

        first_audio_db_collection = 'FirstUserVoice/' + user_voice.filename

        # 텍스트, 사용자의 첫 음성파일 위치 임시 저장
        text_save_dto = {
            'user_id': user_id,
            'text': text,
            'first_audio': first_audio_db_collection
        }
        temp_text_ref = tempText_db.document(temp_save_id)
        temp_text_ref.set(text_save_dto)

        # user_voice 파일 로컬 저장
        user_voice_path = os.path.join(upload_dir, user_voice.filename)
        with open(user_voice_path, "wb") as buffer:
            shutil.copyfileobj(user_voice.file, buffer)

        # tts_voice 파일 로컬 저장 후 Temp에 저장
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

        # 음성 필터링을 위한 사용자 pitch 값 가져오기
        user_data = user_doc.to_dict()
        low = min(user_data.get('low_pitch'),user_data.get('high_pitch'))
        high = max(user_data.get('low_pitch'),user_data.get('high_pitch'))

        # 음성 필터링(노이즈 제거)하고 피치, 진폭 추출
        sampling_rate, filtered_data, pitch_values, time_steps = process_and_save_filtered_audio(input_file_path=user_voice_path, human_voice_range=(low-10, high+10))

        with open(user_voice_path, "rb") as audio_file:
            audio = audio_file.read()

        # 사용자의 첫 음성 파일 저장
        blob = bucket.blob(first_audio_db_collection)
        blob.upload_from_string(audio, content_type="audio/wav")
        
        # Temp 에 필터링 된 사용자 음성 저장
        blob = bucket.blob(temp_db_collection + 'userVoice.wav')
        blob.upload_from_string(audio, content_type="audio/wav")

        # TTS 피치, 진폭 추출
        tts_sampling_rate, tts_data, pitch_values_tts, time_steps_tts = extract_pitch_from_tts(tts_voice_path)

        # TTS, 사용자 타임스탬프 추출
        word_intervals = cal_timestamp(extract_word_timestamps(user_voice_path))
        tts_word_intervals = extract_word_timestamps(tts_voice_path)

        # TTS, 사용자 타임스탬프 보정
        with ThreadPoolExecutor() as executor:
            future_word_intervals = executor.submit(ts_cal, word_intervals, text)
            future_tts_word_intervals = executor.submit(ts_cal, tts_word_intervals, text)

            word_intervals = future_word_intervals.result()
            tts_word_intervals = future_tts_word_intervals.result()

        

        # 멀티스레딩을 사용하여 세 가지 작업을 병렬로 수행
        with ThreadPoolExecutor() as executor:
            future_amp_result = executor.submit(compare_amplitude_differences, word_intervals, tts_word_intervals, filtered_data, tts_data, tts_sampling_rate, sampling_rate)
            future_pitch_result = executor.submit(calculate_pitch_differences, word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts)
            future_segments_result = executor.submit(compare_pitch_differences, word_intervals, pitch_values, tts_word_intervals, pitch_values_tts, time_steps, time_steps_tts)

            # 결과를 기다림
            comp_amp_result, max_word = future_amp_result.result()
            comp_pitch_result = future_pitch_result.result()
            results = future_segments_result.result()

        # # TTS, 사용자 진폭 비교 
        # comp_amp_result, max_word = compare_amplitude_differences(word_intervals, tts_word_intervals, filtered_data, tts_data, tts_sampling_rate, sampling_rate, threshold_value)

        # # TTS, 사용자 피치 비교
        # comp_pitch_result = calculate_pitch_differences(
        # word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts)

        # # 세그먼트 비교(일단 안씀)
        # # highest_segment, lowest_segment = compare_segments(
        # #     word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts
        # # )

        # # TTS, 사용자 이웃한 단어와의 피치 변화 비교
        # results = compare_pitch_differences(word_intervals, pitch_values, tts_word_intervals, pitch_values_tts,time_steps,time_steps_tts, threshold=20)
     
        # 로컬 파일 삭제
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

        # gzip이 효율이 좋지만 압축 해제에서 문제가 생겨 일단 json으로 저장
        # gzip_buffer = BytesIO()
        # with gzip.GzipFile(fileobj=gzip_buffer, mode='w') as f:
        #     f.write(json.dumps(result).encode('utf-8'))
        json_str = json.dumps(result) # 분석 결과 json으로 만들기
        # gzip_buffer.seek(0)

        # 분석 결과 Temp에 저장
        blob = bucket.blob(f"{temp_db_collection}analysis.json")
        blob.upload_from_string(json_str, content_type="application/json")

        response = {
            'temp_id': temp_save_id # Temp 디비 위치 리턴
        }
        # def iterfile():
        #     gzip_buffer.seek(0)
        #     yield from gzip_buffer
        # StreamingResponse(iterfile(), media_type="application/gzip", headers={"Content-Encoding": "gzip"})
        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.post("/get-today-sentence", description="오늘의 문장 가져오기", tags=['Util api'])
async def get_today_sentence():
    try:
        date = datetime.now().date()
        date_int = int(str(date).replace("-", ""))
        idx = date_int % 3

        sentence_ref = todaySentence_db.where('idx', '==', idx).stream()
        
        # 쿼리 결과를 리스트로 변환
        sentence_list = list(sentence_ref)

        if not sentence_list:
            raise HTTPException(status_code=404, detail="오늘의 문장을 찾을 수 없습니다.")

        dto = {
            'data': {
                'sentence': sentence_list[0].to_dict().get('text')
            }
        }

        return dto

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")