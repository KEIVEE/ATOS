from pydantic import BaseModel

class LoginHistoryResDTO(BaseModel):
    login_history: list
    login_count: int