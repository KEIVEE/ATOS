from pydantic import BaseModel
from typing import Optional

class SavePracticeDTO(BaseModel):
    user_id: Optional[str]
    temp_id: Optional[str]
    title: str

