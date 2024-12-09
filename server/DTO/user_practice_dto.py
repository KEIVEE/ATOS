from pydantic import BaseModel
from typing import Optional

class SavePracticeDTO(BaseModel):
    user_id: str
    temp_id: str
    title: str


class UpdatePracticeDTO(BaseModel):
    user_id: str
    title: str
    temp_id: str
    changed_title: Optional[str]

class DeletePracticeDTO(BaseModel):
    user_id: str
    title: str

