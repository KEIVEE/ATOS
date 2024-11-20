from pydantic import BaseModel

class GetTTSReqDTO(BaseModel):
    user_id: str
    text: str
    sex: str
    theme: str

class GetTTSAudioDTO(BaseModel):
    audio_path: str
