from pydantic import BaseModel
from typing import List, Optional

class AgentState(BaseModel):
    messages: List[str]
    screen_base64: Optional[str] = None