import google.cloud.texttospeech as texttospeech

def getTTS() :
    key_path = '/Users/jichan/Desktop/대학/3-2/캡스톤/key/gc_key/cd24-2-59737e481a51.json'
    client = texttospeech.TextToSpeechClient.from_service_account_file(key_path)

    # TTS 요청을 위한 텍스트 입력 설정
    text_input = texttospeech.SynthesisInput(text="안녕하세요! 구글 클라우드 TTS를 사용하여 텍스트를 음성으로 변환하고 있습니다.")

    # 음성 구성 설정 (언어 코드와 목소리 유형 지정)
    voice = texttospeech.VoiceSelectionParams(
        name="ko-KR-Wavenet-A",
        language_code="ko-KR",  # 한국어
        ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL  # 중성적인 목소리
        )

    # 오디오 설정 (출력 형식을 MP3로 지정)
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=1.2
    )

    # TTS 요청 보내기
    response = client.synthesize_speech(
        input=text_input,
        voice=voice,
        audio_config=audio_config
    )

    return response.audio_content

if __name__ == "__main__":
    getTTS()


# # 결과 저장
# with open("output.mp3", "wb") as out:
#     out.write(response.audio_content)
#     print("음성 파일이 'output.mp3'로 저장되었습니다.")


