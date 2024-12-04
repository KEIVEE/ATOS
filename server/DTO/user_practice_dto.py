from pydantic import BaseModel
from typing import Optional

class SavePracticeDTO(BaseModel):
    user_id: Optional[str]
    temp_id: Optional[str]
    title: str


class UpdatePracticeDTO(BaseModel):
    user_id: str
    title: str
    temp_id: str
    changed_title: Optional[str]

