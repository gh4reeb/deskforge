from fastapi import FastAPI
import base64
from PIL import Image
import io
from .graph import create_graph
from .models import AgentState
from pydantic import BaseModel
from .memory import store_memory
import os

app = FastAPI()

graph = create_graph()

class TaskRequest(BaseModel):
    task: str

ALLOWED_TOOLS = ["take_screenshot", "mouse_click", "type_text", "read_file", "write_file"]
FORBIDDEN_PATHS = ["/home", "/etc", "/usr", "/var", "/root", "/boot", "/sys", "/proc", "/dev", "C:\\Users", "C:\\Windows", "C:\\System32"]

def check_security(tool_name, **kwargs):
    if tool_name not in ALLOWED_TOOLS:
        return False, f"Tool {tool_name} not allowed"
    if tool_name in ["read_file", "write_file"]:
        path = kwargs.get("path", "")
        for forbidden in FORBIDDEN_PATHS:
            if path.startswith(forbidden):
                return False, f"Access to {path} is forbidden"
    # For MVP, auto-approve
    return True, "Approved"

# Tool implementations
def take_screenshot():
    try:
        import pyautogui
        screenshot = pyautogui.screenshot()
        buffered = io.BytesIO()
        screenshot.save(buffered, format="PNG")
        return base64.b64encode(buffered.getvalue()).decode()
    except:
        return "Screenshot not available"

def mouse_click(x: int, y: int):
    allowed, msg = check_security("mouse_click", x=x, y=y)
    if not allowed:
        return msg
    try:
        import pyautogui
        pyautogui.click(x, y)
        return f"Clicked at {x},{y}"
    except:
        return "Mouse click failed"

def type_text(text: str):
    allowed, msg = check_security("type_text", text=text)
    if not allowed:
        return msg
    try:
        import pyautogui
        pyautogui.typewrite(text)
        return f"Typed: {text}"
    except:
        return "Typing failed"

def read_file(path: str):
    allowed, msg = check_security("read_file", path=path)
    if not allowed:
        return msg
    try:
        with open(path, 'r') as f:
            return f.read()
    except:
        return "Read failed"

def write_file(path: str, content: str):
    allowed, msg = check_security("write_file", path=path)
    if not allowed:
        return msg
    try:
        with open(path, 'w') as f:
            f.write(content)
        return f"Written to {path}"
    except:
        return "Write failed"

@app.get("/")
def read_root():
    return {"status": "DeskForge backend running", "version": "0.1.0"}

@app.post("/run-agent")
async def run_agent(request: TaskRequest):
    initial_state = AgentState(messages=[request.task])
    result = graph.invoke(initial_state)
    response = {"result": result.messages[-1], "screen": take_screenshot()}
    store_memory(request.task, response["result"])
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8001)