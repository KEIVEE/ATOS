import firebase_admin
from firebase_admin import credentials

key_path = '/Users/jichan/Desktop/대학/3-2/캡스톤/key/firebase_key/atos-cd1-firebase-adminsdk-5vlmg-b99ed3548b.json'
cred = credentials.Certificate(key_path)

def init_server():
    firebase_admin.initialize_app(cred)

if __name__ == "__main__":
    init_server()