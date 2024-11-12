import whisperx
import gc
import torch

torch.backends.cudnn.benchmark = True

def extract_word_timestamps(audio_file, model_size="medium", device='cuda', batch_size=16, compute_type="float16"):

    #print("Is CUDA available:", torch.cuda.is_available())
    #print("Number of CUDA devices:", torch.cuda.device_count())

    # 1. Whisper 모델 로드 및 음성 텍스트 변환
    model = whisperx.load_model(model_size, device, compute_type=compute_type, language = "ko")

    # 오디오 파일 로드
    audio = whisperx.load_audio(audio_file)
    result = model.transcribe(audio, batch_size=batch_size, language="ko")

    # 2. Whisper 출력 정렬
    model_a, metadata = whisperx.load_align_model(language_code=result["language"], device=device)
    result = whisperx.align(result["segments"], model_a, metadata, audio, device, return_char_alignments=False)

    # 3. 단어별 타임스탬프 리스트 생성
    timestamps = []
    for segment in result["segments"]:
        for word in segment["words"]:
            timestamps.append({
                "word": word["word"],
                "start": word["start"],
                "end": word["end"]
            })

    return timestamps