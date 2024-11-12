import numpy as np

# Gradient 계산 함수
def calculate_pitch_gradients(pitch_values, time_steps):
    gradients = []

    # 피치 기울기 계산
    for i in range(1, len(pitch_values)):
        if pitch_values[i] > 0 and pitch_values[i-1] > 0:  # 피치가 0보다 큰 경우에만 계산
            gradient = (pitch_values[i] - pitch_values[i-1]) / (time_steps[i] - time_steps[i-1])
            gradients.append(gradient)

    return gradients

# 세그먼트 기울기 비교 함수
def compare_segments(user_segments, tts_segments, user_pitch_values, user_time_steps, tts_pitch_values, tts_time_steps):
    highest_segment = None
    lowest_segment = None
    highest_difference = -float('inf')  # Initialize to negative infinity for maximum comparison
    lowest_difference = float('inf')    # Initialize to positive infinity for minimum comparison

    for user_segment, tts_segment in zip(user_segments, tts_segments):
        # 해당 세그먼트의 피치 값 및 타임스탬프 추출
        user_indices = [i for i, t in enumerate(user_time_steps) if user_segment['start'] <= t <= user_segment['end']]
        tts_indices = [i for i, t in enumerate(tts_time_steps) if tts_segment['start'] <= t <= tts_segment['end']]

        # 피치 기울기 계산
        if user_indices and tts_indices:
            user_segment_pitch = user_pitch_values[user_indices[0]:user_indices[-1] + 1]
            user_segment_time = user_time_steps[user_indices[0]:user_indices[-1] + 1]
            tts_segment_pitch = tts_pitch_values[tts_indices[0]:tts_indices[-1] + 1]
            tts_segment_time = tts_time_steps[tts_indices[0]:tts_indices[-1] + 1]

            user_gradients = calculate_pitch_gradients(user_segment_pitch, user_segment_time)
            tts_gradients = calculate_pitch_gradients(tts_segment_pitch, tts_segment_time)

            # 기울기 차이 계산
            if user_gradients and tts_gradients:
                avg_user_gradient = np.mean(user_gradients)
                avg_tts_gradient = np.mean(tts_gradients)
                difference = avg_user_gradient - avg_tts_gradient

                # 가장 높은 기울기 차이를 기록 (양의 방향)
                if difference > highest_difference:
                    highest_difference = difference
                    highest_segment = (user_segment, tts_segment, avg_user_gradient, avg_tts_gradient)

                # 가장 낮은 기울기 차이를 기록 (음의 방향)
                if difference < lowest_difference:
                    lowest_difference = difference
                    lowest_segment = (user_segment, tts_segment, avg_user_gradient, avg_tts_gradient)

    return highest_segment, lowest_segment
