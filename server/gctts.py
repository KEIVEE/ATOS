import google.cloud.texttospeech as texttospeech
from server.settings import GC_TTS_KEY

def getTTS(tts, sex, speaking_rate=1.2): 
    key_path = GC_TTS_KEY
    client = texttospeech.TextToSpeechClient.from_service_account_file(key_path)

    # TTS 요청을 위한 텍스트 입력 설정
    text_input = texttospeech.SynthesisInput(text=tts)

    voice_model = 'ko-KR-Wavenet-A'

    if sex == 'male' or sex == 'Male':
        voice_model = 'ko-KR-Wavenet-C'

    # 음성 구성 설정 (언어 코드와 목소리 유형 지정)
    voice = texttospeech.VoiceSelectionParams(
        name=voice_model,  
        language_code="ko-KR",  # 한국어
        ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL  # 중성적인 목소리
        )

    # 오디오 설정 (출력 형식을 MP3로 지정)
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

# # 결과 저장
# with open("output.mp3", "wb") as out:
#     out.write(response.audio_content)
#     print("음성 파일이 'output.mp3'로 저장되었습니다.")


