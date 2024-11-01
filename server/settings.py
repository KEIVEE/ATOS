from dotenv import load_dotenv
import os

load_dotenv()
GPT_KEY = os.getenv('GPT_KEY','')
GC_TTS_KEY = os.getenv('GC_TTS_KEY')
FB_KEY = os.getenv('FB_KEY')