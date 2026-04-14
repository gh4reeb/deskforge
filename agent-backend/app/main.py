from fastapi import FastAPI
import base64
from PIL import Image
import io
from .graph import create_graph
from .models import AgentState
from pydantic import BaseModel
from .memory import store_memory

app = FastAPI()

graph = create_graph()

class TaskRequest(BaseModel):
    task: str

@app.get("/")
def read_root():
    return {"status": "DeskForge backend running", "version": "0.1.0"}

# Tool examples
def take_screenshot():
    try:
        import pyautogui
        screenshot = pyautogui.screenshot()
        buffered = io.BytesIO()
        screenshot.save(buffered, format="PNG")
        return base64.b64encode(buffered.getvalue()).decode()
    except:
        return "Mock screenshot base64"

def mouse_click(x: int, y: int):
    try:
        import pyautogui
        pyautogui.click(x, y)
        return f"Clicked at {x},{y}"
    except:
        return f"Mock click at {x},{y}"

@app.post("/run-agent")
async def run_agent(request: TaskRequest):
    # initial_state = AgentState(messages=[request.task])
    # result = graph.invoke(initial_state)
    # return {"result": result.messages[-1], "screen": take_screenshot()}
    response = {"result": "Mock response for " + request.task, "screen": take_screenshot()}
    store_memory(request.task, response["result"])
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)