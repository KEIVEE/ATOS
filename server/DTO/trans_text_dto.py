from pydantic import BaseModel

class TransTextDTO(BaseModel):
    text : str
    user_id : str
    region : str
    theme : str
    sex : str

class TransTextReDTO(BaseModel):
    text_id: str
    text_data: str
    translated_text_id: str
    translated_text_data: str
    audio_title: str