import server_init

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

from fastapi import FastAPI

if not firebase_admin._apps:  # 이미 초기화된 앱이 없으면 초기화
    server_init.init_server()

db = firestore.client()
app = FastAPI()

@app.get("/")
def read_root():
    return {'message' : 'Server for ATOS project '}


