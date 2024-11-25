import google.cloud.texttospeech as texttospeech
from server.settings import GC_TTS_KEY

# 구글 클라우드 TTS 생성
def getTTS(tts, sex, speaking_rate=1.2): 
    key_path = GC_TTS_KEY
    client = texttospeech.TextToSpeechClient.from_service_account_file(key_path)

    # TTS 요청을 위한 텍스트 입력 설정
    text_input = texttospeech.SynthesisInput(text=tts)

    # 여성 목소리
    voice_model = 'ko-KR-Wavenet-A'

    # 남성 목소리
    if sex == 'male' or sex == 'Male':
        voice_model = 'ko-KR-Wavenet-C'

    # 음성 구성 설정 (언어와 목소리 유형 지정)
    voice = texttospeech.VoiceSelectionParams(
        name=voice_model,  
        language_code="ko-KR", 
        ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL  
        )

    # 오디오 설정 (출력 형식을 wav로 지정)
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16,
        speaking_rate=speaking_rate
    )

    # TTS 요청 보내기
    response = client.synthesize_speech(
        input=text_input,
        voice=voice,
        audio_config=audio_config
    )

    return response.audio_content


