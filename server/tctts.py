import requests 
import time
from server.settings import TC_TTS_KEY, TC_TTS_KEY2, TC_TTS_KEY3

#actor_id = '648aaee9248bcd37dad435e6'

def getTCTTS(text, theme=2):

    selected_key = ''
    if theme == 1:
        selected_key = TC_TTS_KEY
    elif theme == 2:
        selected_key = TC_TTS_KEY2
    elif theme == 3:
        selected_key = TC_TTS_KEY3

    header = {
        'Authorization': f'Bearer {selected_key}'
    }
    r = requests.get('https://typecast.ai/api/actor', headers=header)
    my_actors = r.json()['result']
    my_actor = my_actors[0]
    actor_id = my_actor['actor_id']

    url = "https://typecast.ai/api/speak"

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


