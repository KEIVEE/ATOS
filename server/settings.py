from dotenv import load_dotenv
import os

load_dotenv("server/.env")
GPT_KEY = os.getenv('GPT_KEY','')
GC_TTS_KEY = os.getenv('GC_TTS_KEY')
FB_KEY = os.getenv('FB_KEY')
TC_TTS_KEY = os.getenv('TC_TTS_KEY')
TC_TTS_KEY2 = os.getenv('TC_TTS_KEY2')
TC_TTS_KEY3 = os.getenv('TC_TTS_KEY3')