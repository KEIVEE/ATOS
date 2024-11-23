from pydantic import BaseModel

class LoginHistory(BaseModel):
    login_date: str
    user_id: str

class LoginHistoryResDTO(BaseModel):
    login_history: list[LoginHistory]
    login_count: int