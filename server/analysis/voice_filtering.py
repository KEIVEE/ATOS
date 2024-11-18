#인간의 음역대만 따와서 필터링한다. 여유시간을 둬서 완성도 있게 필터링함.
import parselmouth
import scipy.io.wavfile as wav
import numpy as np

def process_and_save_filtered_audio(input_file_path, output_file_path = "server/filtered_audio", human_voice_range=(30, 255), extend_ms=50, silence_after_ms=150):
    """
    입력 WAV 파일에서 인간 음역대만 필터링하여 결과를 반환하고, 새 파일로 저장하는 함수.

    Args:
        input_file_path (str): 입력 WAV 파일 경로.
        output_file_path (str): 출력 필터링된 WAV 파일 경로.
        human_voice_range (tuple): 인간 음역대 (최소 Hz, 최대 Hz).
        extend_ms (int): 유지할 길이 (밀리초).
        silence_after_ms (int): 여유 시간 (밀리초).

    Returns:
        filtered_data (numpy.ndarray): 필터링된 오디오 데이터.
        pitch_values (numpy.ndarray): 피치 값 배열.
        time_steps (numpy.ndarray): 시간 단계 배열.
    """
    output_file_path = input_file_path

    # 1. WAV 파일 로드
    sampling_rate, data = wav.read(input_file_path)

    # 스테레오일 경우 단일 채널로 변환
    if len(data.shape) > 1:
        data = data.mean(axis=1).astype(np.int16)

    # 2. parselmouth로 음성 분석
    snd = parselmouth.Sound(data, sampling_rate)

    # 피치 분석
    pitch = snd.to_pitch()

    # 피치 값과 해당 시간 단계 가져오기
    pitch_values = pitch.selected_array["frequency"]
    time_steps = pitch.xs()

    # 3. 히스테리시스 필터 적용
    filtered_data = np.zeros_like(data, dtype=np.float32)
    prev_in_range = False

    # 샘플 수로 변환
    extend_samples = int(sampling_rate * extend_ms / 1000)
    silence_samples = int(sampling_rate * silence_after_ms / 1000)

    for i, t in enumerate(time_steps):
        index = int(t * sampling_rate)

        # 현재 피치가 인간 음역대에 해당하는지 확인
        in_range = human_voice_range[0] <= pitch_values[i] <= human_voice_range[1]

        if in_range or prev_in_range:
            # 앞뒤로 extend_ms만큼 구간을 유지
            start = max(0, index - extend_samples)
            end = min(len(data), index + extend_samples + silence_samples)
            filtered_data[start:end] = data[start:end]

        prev_in_range = in_range

    # 4. 결과 WAV 파일 저장
    wav.write(output_file_path, sampling_rate, filtered_data.astype(np.int16))

    print(f"{output_file_path} 파일이 생성되었습니다.")
    return sampling_rate, filtered_data, pitch_values, time_steps

# filtered_data : 진폭 샘플링 리스트