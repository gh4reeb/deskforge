from pydantic import BaseModel

class AgentState(BaseModel):
    messages: list
    screen_base64: str | None = None