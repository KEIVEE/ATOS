from pydantic import BaseModel

class GetTTSReqDTO(BaseModel):
    user_id: str
    text: str
    sex: str
    theme: str
