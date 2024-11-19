init_call_os_text = True  # 처음에는 True로 설정
init_call_os_audio = True 

# 텍스트 디비 변경 시 실행
def os_text(doc_snapshot, changes, read_time):
    global init_call_os_text
    if init_call_os_text:
        init_call_os_text = False  # 최초 호출 후 초기 호출 여부를 False로 변경
        return  # 최초 호출일 경우 아무 것도 하지 않고 리턴
    for change in changes:
        print(f'Received text snapshot: {change.document.id} => {change.document.to_dict()}')
        
        if(change.type.name == 'ADDED') :
            print("text added")
            toTranslate = change.document.to_dict() # 바뀐 텍스트 가져오기

            translated_text = tt.gpt_test(toTranslate.get('text')) # gpt api 무한루프 돌 수도 있으니까 테스트로 일단 실행
            #translated_text = tt.gpt_translate(toTranslate.get('text'))

            text_dto = {'text' : translated_text}
            print("번역된 텍스트 : " + translated_text)

            audio = tts.getTTS(translated_text)
            blob = bucket.blob("gcTTS/"+change.document.id+".wav")
            blob.upload_from_string(audio, content_type="audio/wav")
            print("번역 텍스트 TTS 오디오 파일 저장")

            translatedText_db.add(text_dto)

            
        ## gpt api로 번역하고 디비에 저장하기
        ## 번역한 text tts 로 음성파일 디비에 저장하기

# 음성 디비 변경 시 실행
def os_audio(doc_snapshot, changes, read_time):
    global init_call_os_audio
    if init_call_os_audio:
        init_call_os_audio = False  # 최초 호출 후 초기 호출 여부를 False로 변경
        return  # 최초 호출일 경우 아무 것도 하지 않고 리턴
    for change in changes:
        print(f'Received audio snapshot: {change.document.id} => {change.document.to_dict()}')
        
        if(change.type.name == 'ADDED') :
            toAnalyze = change.document.to_dict() # 바뀐 오디오 이름 가져오기
            blob_name = audio_blob_name + toAnalyze['name'] 
            blob = bucket.blob(blob_name)
            audio_data = blob.download_as_bytes()
            print("음성 파일이 바이트 변수에 성공적으로 저장되었습니다.")
            print(f"바이트 데이터 길이: {len(audio_data)}")

            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_wav_file:
                temp_wav_file.write(audio_data)
                temp_wav_file_path = temp_wav_file.name # 임시 파일 경로
                print("음성 temp파일 저장 완료")

## 음성파일의 경우 storage 에 저장되므로 직접적인 변화 감지가 불가능
## 따라서 firestore에 음성파일의 제목만을 저장하는 텍스트 디비를 만들고 이 디비의 변화를 감지

# 디비 리스너 (변화 감지)
# text_watch = toTranslateText_db.on_snapshot(os_text)
# audio_watch = userAudio_db.on_snapshot(os_audio)