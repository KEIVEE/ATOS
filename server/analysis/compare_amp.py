import numpy as np

def compare_amplitude_differences(user_word_intervals, tts_word_intervals, filtered_data, tts_data, tts_sampling_rate, sampling_rate, threshold = 5000):
    # 데이터 타입을 float으로 변환하여 오버플로우 방지
    filtered_data = filtered_data.astype(np.float32)
    tts_data = tts_data.astype(np.float32)
    max_diff_word = None
    max_amplitude_difference = 0  # 최고 진폭 차이 추적용
    user_threshold_exceeding_words = []
    tts_threshold_exceeding_words = []
    result = []
    for idx, (user_word, tts_word) in enumerate(zip(user_word_intervals, tts_word_intervals)):
        # 사용자 음성 단어 세그먼트의 시작과 끝 인덱스 계산
        user_start_idx = int(user_word['start'] * sampling_rate)
        user_end_idx = int(user_word['end'] * sampling_rate)

        # TTS 음성 단어 세그먼트의 시작과 끝 인덱스 계산
        tts_start_idx = int(tts_word['start'] * tts_sampling_rate)
        tts_end_idx = int(tts_word['end'] * tts_sampling_rate)

        # 사용자 음성의 진폭 값 중 100 이상인 값만 필터링
        user_amplitude = filtered_data[user_start_idx:user_end_idx]
        user_amplitude = user_amplitude[user_amplitude >= 100]

        # TTS 음성의 진폭 값 중 100 이상인 값만 필터링
        tts_amplitude = tts_data[tts_start_idx:tts_end_idx]
        tts_amplitude = tts_amplitude[tts_amplitude >= 100]

        # 사용자와 TTS 음성의 최대 및 최소 진폭 계산 (필터링된 값만 사용)
        if len(user_amplitude) > 0 and len(tts_amplitude) > 0:
            user_max_amplitude = np.max(user_amplitude)
            user_min_amplitude = np.min(user_amplitude)
            user_amplitude_difference = user_max_amplitude - user_min_amplitude

            tts_max_amplitude = np.max(tts_amplitude)
            tts_min_amplitude = np.min(tts_amplitude)
            tts_amplitude_difference = tts_max_amplitude - tts_min_amplitude

            max_amplitude_difference_temp = user_max_amplitude - tts_max_amplitude

            if max_amplitude_difference < max_amplitude_difference_temp :
              max_amplitude_difference = max_amplitude_difference_temp
              max_diff_word = {"word": user_word['word'], "idx": idx}
            if user_amplitude_difference - tts_amplitude_difference > threshold :
              #user_threshold_exceeding_words.append({"word": user_word['word'], "idx": idx})
              result.append(1)

            elif tts_amplitude_difference - user_amplitude_difference > threshold:
              #tts_threshold_exceeding_words.append({"word": user_word['word'], "idx": idx})
              result.append(-1)

            else:
              result.append(0)

            '''
            # 진폭 차이 비교
            amplitude_diff = abs(user_amplitude_difference - tts_amplitude_difference)
            if amplitude_diff > threshold:
                print(f"단어: {user_word['word']}, 사용자 진폭 차이: {user_amplitude_difference}, TTS 진폭 차이: {tts_amplitude_difference}, 차이: {amplitude_diff}")

              '''


    return result, max_diff_word