from pydantic import BaseModel

class SavePracticeDTO(BaseModel):
    user_id: str
    temp_id: str
    title: str
    description: str

