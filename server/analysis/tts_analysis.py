import parselmouth
import scipy.io.wavfile as wav
import numpy as np

def extract_pitch_from_tts(file_path):
    """
    TTS 음성을 분석하여 피치 값을 추출하는 함수.

    매개변수:
    file_path (str): TTS 음성 파일 경로 (WAV 형식).

    반환값:
    tuple: (샘플링 레이트, 피치 값 배열, 시간 단계 배열)
    """
    # 1. WAV 파일 로드
    tts_sampling_rate, tts_data = wav.read(file_path)

    # 스테레오일 경우 단일 채널로 변환
    if len(tts_data.shape) > 1:
        tts_data = tts_data.mean(axis=1).astype(np.int16)

    # 2. parselmouth로 음성 분석
    snd = parselmouth.Sound(tts_data, tts_sampling_rate)

    # 피치 분석
    pitch = snd.to_pitch()

    # 피치 값과 해당 시간 단계 가져오기
    pitch_values_tts = pitch.selected_array["frequency"]
    time_steps_tts = pitch.xs()

    # 피치 값과 시간 단계 배열 반환
    return tts_sampling_rate, tts_data, pitch_values_tts, time_steps_tts
