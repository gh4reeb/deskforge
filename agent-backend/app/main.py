from fastapi import FastAPI
from .graph import create_graph
from .models import AgentState
from .memory import store_memory
from .tools import take_screenshot, mouse_click, type_text, read_file, write_file, browse_web
from pydantic import BaseModel
import os

app = FastAPI()

graph = create_graph()

class TaskRequest(BaseModel):
    task: str
    persona: str = "general"

@app.get("/")
def read_root():
    return {"status": "DeskForge backend running", "version": "0.1.0"}

@app.post("/run-agent")
async def run_agent(request: TaskRequest):
    persona = getattr(request, 'persona', 'general')
    initial_state = AgentState(messages=[f"Persona: {persona}. Task: {request.task}"])
    result = graph.invoke(initial_state)
    messages = getattr(result, 'messages', None)
    if messages is None and isinstance(result, dict):
        messages = result.get('messages', [])
    output = messages[-1] if messages else str(result)
    response = {"result": output, "screen": take_screenshot()}
    store_memory(request.task, response["result"])
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)