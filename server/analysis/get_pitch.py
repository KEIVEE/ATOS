import numpy as np
import parselmouth

def get_pitch_median(file_path):
    """
    주어진 WAV 파일에서 피치의 중간값을 계산하는 함수.

    Args:
        file_path (str): WAV 파일 경로.

    Returns:
        pitch_median (float): 0이 아닌 피치 값들의 중간값.
    """
    # WAV 파일 로드
    snd = parselmouth.Sound(file_path)

    # 피치 분석
    pitch = snd.to_pitch()

    # 피치 값과 해당 시간 단계 가져오기
    pitch_values = pitch.selected_array["frequency"]

    # 0이 아닌 피치 값만 필터링
    non_zero_pitch_values = pitch_values[pitch_values > 0]

    # 중간값 계산
    if len(non_zero_pitch_values) > 0:
        pitch_median = np.median(non_zero_pitch_values)
    else:
        pitch_median = 0  # 만약 0이 아닌 피치가 없다면 0으로 처리

    return pitch_median