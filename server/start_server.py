import server.server_init as server_init
import server.text_translate as tt
import server.gctts as tts

import tempfile

import firebase_admin
from firebase_admin import firestore
from firebase_admin import storage

from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import StreamingResponse
from io import BytesIO

from server.DTO.set_user_dto import UserDTO
from server.DTO.trans_text_dto import TransTextDTO, TransTextReDTO

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

        user_ref = userData_db.document()
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

        audio_db_collection = 'gcTTS'
        audio_type = '.wav'
        audio = tts.getTTS(translated_text)
        blob = bucket.blob(audio_db_collection + translated_text_ref.id + audio_type)
        blob.upload_from_string(audio, content_type="audio/wav")

        response_dto = response_dto = TransTextReDTO(
            text_id=text_ref.id,
            text_data=text_save_dto,
            translated_text_id=translated_text_ref.id,
            translated_text_data=trans_text_save_dto,
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

        audio_db_collection = 'gcTTS'
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


