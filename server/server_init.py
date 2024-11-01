import firebase_admin
from firebase_admin import credentials
from server.settings import FB_KEY

key_path = FB_KEY
cred = credentials.Certificate(key_path)

def init_server():
    firebase_admin.initialize_app(cred)

if __name__ == "__main__":
    init_server()