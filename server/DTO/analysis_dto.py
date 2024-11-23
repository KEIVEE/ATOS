from pydantic import BaseModel
from typing import List, Any

class AnalysisResult(BaseModel):
    word_intervals: Any
    tts_word_intervals: Any
    user_exceeding_words: Any
    tts_exceeding_words: Any
    max_word: Any
    u_results: Any
    t_results: Any
    highest_segment: Any
    lowest_segment: Any
    tts_data: List[float]
    filtered_data: List[float]
    sampling_rate: int
    tts_sampling_rate: int
    pitch_values: List[float]
    time_steps: List[float]
    pitch_values_tts: List[float]
    time_steps_tts: List[float]
    results: List[int]

class VoiceAnalysisResponse(BaseModel):
    temp_id: str
    result: AnalysisResult

class VoiceAnalysisResponse2(BaseModel):
    temp_id: str