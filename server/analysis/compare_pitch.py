import numpy as np

def calculate_pitch_differences(word_intervals, tts_word_intervals, pitch_values, time_steps, pitch_values_tts, time_steps_tts, threshold=25):
    """
    사용자와 TTS 단어의 피치 차이를 계산하고 결과를 반환하는 함수.

    Args:
        word_intervals (list): 사용자의 단어 간격 리스트.
        tts_word_intervals (list): TTS 단어 간격 리스트.
        pitch_values (np.array): 사용자 음성의 피치 값 배열.
        time_steps (np.array): 사용자 음성의 타임스탬프 배열.
        pitch_values_tts (np.array): TTS 음성의 피치 값 배열.
        time_steps_tts (np.array): TTS 음성의 타임스탬프 배열.
        threshold (int): 피치 차이 임계값.

    Returns:
        list: 피치 차이가 임계값을 초과하는 단어의 결과 리스트.
    """
    user_results = []
    tts_results = []
    # 사용자 단어와 TTS 단어의 피치 차이 계산
    result = []
    for i in range(min(len(word_intervals), len(tts_word_intervals))):  # 단어 개수의 최소값으로 루프
        user_word = word_intervals[i]  # 사용자의 단어
        tts_word = tts_word_intervals[i]  # TTS 단어

        # 사용자 피치 샘플링 추출 (0이 아닌 값만 선택)
        user_pitch_samples = pitch_values[(time_steps >= user_word['start']) & (time_steps <= user_word['end'])]
        user_time_samples = time_steps[(time_steps >= user_word['start']) & (time_steps <= user_word['end'])]
        user_pitch_samples = user_pitch_samples[user_pitch_samples > 0]  # 0이 아닌 값만 포함

        if len(user_pitch_samples) > 0:
            user_pitch_max = np.max(user_pitch_samples)
            user_pitch_min = np.min(user_pitch_samples)
            user_pitch_diff = user_pitch_max - user_pitch_min
            user_max_time = user_time_samples[np.argmax(user_pitch_samples)]  # 최대 피치에 해당하는 시간

            # TTS 피치 샘플링 추출 (0이 아닌 값만 선택)
            tts_pitch_samples = pitch_values_tts[(time_steps_tts >= tts_word['start']) & (time_steps_tts <= tts_word['end'])]
            tts_time_samples = time_steps_tts[(time_steps_tts >= tts_word['start']) & (time_steps_tts <= tts_word['end'])]
            tts_pitch_samples = tts_pitch_samples[tts_pitch_samples > 0]  # 0이 아닌 값만 포함

            if len(tts_pitch_samples) > 0:
                tts_pitch_max = np.max(tts_pitch_samples)
                tts_pitch_min = np.min(tts_pitch_samples)
                tts_pitch_diff = tts_pitch_max - tts_pitch_min
                tts_max_time = tts_time_samples[np.argmax(tts_pitch_samples)]  # 최대 피치에 해당하는 시간
                if user_pitch_diff - tts_pitch_diff > threshold:
                    result.append(1)
                elif tts_pitch_diff - user_pitch_diff > threshold:
                    result.append(-1)
                else:
                    result.append(0)

                '''
                # 피치 차이가 임계값 초과하는 경우 결과 저장
                if user_pitch_diff > threshold or tts_pitch_diff > threshold:
                    results.append({
                        'user_word': user_word['word'],
                        'tts_word': tts_word['word'],
                        'user_diff': user_pitch_diff,
                        'user_max_pitch': user_pitch_max,
                        'user_max_time': user_max_time,
                        'user_min_pitch': user_pitch_min,
                        'tts_diff': tts_pitch_diff,
                        'tts_max_pitch': tts_pitch_max,
                        'tts_max_time': tts_max_time,
                        'tts_min_pitch': tts_pitch_min
                    })

                '''

    return result

