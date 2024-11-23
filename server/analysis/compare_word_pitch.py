import numpy as np

def compare_pitch_differences(user_timestamps, user_pitch_values, tts_timestamps, tts_pitch_values, user_time_steps, tts_time_steps, threshold=20):
    """
    사용자와 TTS 간 피치 차이를 비교하고 결과를 반환.

    Args:
        user_timestamps (list of dict): 사용자 음성의 타임스탬프 정보.
        user_pitch_values (numpy.ndarray): 사용자 음성의 피치 값 배열.
        tts_timestamps (list of dict): TTS 음성의 타임스탬프 정보.
        tts_pitch_values (numpy.ndarray): TTS 음성의 피치 값 배열.
        user_time_steps (list of float): 사용자 음성의 각 time_step(샘플 시간).
        tts_time_steps (list of float): TTS 음성의 각 time_step(샘플 시간).
        threshold (int): 임계값.

    Returns:
        list of dict: 단어와 비교 결과 (1, -1, 0)를 포함한 리스트.
    """

    # 단어가 하나뿐인 경우 예외 처리
    if len(user_timestamps) <= 1 or len(tts_timestamps) <= 1:
        return -100

    def calculate_average_pitch_from_time_steps(time_steps, pitch_values, timestamps):
        """time_steps와 pitch_values를 사용하여 평균 피치를 계산 (0인 값을 제외)."""
        averages = []
        for i in range(len(timestamps)):
            start_time = timestamps[i]["start"]
            end_time = timestamps[i]["end"]

            # time_steps에서 해당 시간 구간의 인덱스를 찾기
            start_idx = np.searchsorted(time_steps, start_time)
            end_idx = np.searchsorted(time_steps, end_time)

            # 해당 구간의 피치 값을 추출
            pitch_segment = pitch_values[start_idx:end_idx]

            # 0인 값을 제외한 피치 값들만 평균 계산
            non_zero_pitches = pitch_segment[pitch_segment != 0]

            # 평균 계산 (0인 값 제외)
            avg_pitch = np.mean(non_zero_pitches) if len(non_zero_pitches) > 0 else 0

            averages.append(avg_pitch)
        return averages

    # 사용자와 TTS의 평균 피치 계산
    user_avg_pitches = calculate_average_pitch_from_time_steps(user_time_steps, user_pitch_values, user_timestamps)
    tts_avg_pitches = calculate_average_pitch_from_time_steps(tts_time_steps, tts_pitch_values, tts_timestamps)

    # 단어별 피치 차이 계산
    results = []
    for i in range(1, len(user_avg_pitches)):  # 첫 단어는 비교 제외
        user_diff = user_avg_pitches[i] - user_avg_pitches[i - 1]
        tts_diff = tts_avg_pitches[i] - tts_avg_pitches[i - 1]
        diff_difference = user_diff - tts_diff

        # 임계값에 따른 결과 저장
        if diff_difference > threshold:
            result = 1
        elif diff_difference < -threshold:
            result = -1
        else:
            result = 0

        results.append(result)

    return results