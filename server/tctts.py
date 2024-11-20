import requests 
import time
from server.settings import TC_TTS_KEY

actor_id = '658d1bc867f8ac8fa3cbbeec'

def getTCTTS(text):
    url = "https://typecast.ai/api/speak"
    header = {
        'Authorization': f'Bearer {TC_TTS_KEY}'
        }

    r = requests.post(url, headers=header, json={
        'actor_id': actor_id, 
        'text': text, 
        'lang': 'auto', 
        'tempo': 1, 
        'volume': 100, 
        'pitch': 0, 
        'xapi_hd': True, 
        'model_version': 'latest', 
        'xapi_audio_format': 'wav'
        })
    
    audio_url = r.json()['result']['speak_v2_url']
    
    for _ in range(120):
        r = requests.get(audio_url, headers=header)
        ret = r.json()['result']

        if ret['status'] == 'done':
            r = requests.get(ret['audio_download_url'])
            return r.content
        
        else:
            print(f"status: {ret['status']}, waiting 1 second")
            time.sleep(1)

    return None


