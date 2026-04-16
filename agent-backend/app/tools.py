import base64
import io
import os
from typing import Tuple

ALLOWED_TOOLS = ["take_screenshot", "mouse_click", "type_text", "read_file", "write_file", "browse_web"]
FORBIDDEN_PATHS = ["/home", "/etc", "/usr", "/var", "/root", "/boot", "/sys", "/proc", "/dev", "C:\\Users", "C:\\Windows", "C:\\System32"]


def check_security(tool_name: str, **kwargs) -> Tuple[bool, str]:
    if tool_name not in ALLOWED_TOOLS:
        return False, f"Tool {tool_name} not allowed"
    if tool_name in ["read_file", "write_file"]:
        path = kwargs.get("path", "")
        for forbidden in FORBIDDEN_PATHS:
            if path.startswith(forbidden):
                return False, f"Access to {path} is forbidden"
    return True, "Approved"


# Tool implementations

def take_screenshot() -> str:
    if os.name == 'posix' and not (os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY')):
        return "Screenshot not available"
    try:
        import pyautogui
        screenshot = pyautogui.screenshot()
        buffered = io.BytesIO()
        screenshot.save(buffered, format="PNG")
        return base64.b64encode(buffered.getvalue()).decode()
    except Exception:
        return "Screenshot not available"


def mouse_click(x: int, y: int) -> str:
    allowed, msg = check_security("mouse_click", x=x, y=y)
    if not allowed:
        return msg
    try:
        import pyautogui
        pyautogui.click(x, y)
        return f"Clicked at {x},{y}"
    except Exception:
        return "Mouse click failed"


def type_text(text: str) -> str:
    allowed, msg = check_security("type_text", text=text)
    if not allowed:
        return msg
    try:
        import pyautogui
        pyautogui.typewrite(text)
        return f"Typed: {text}"
    except Exception:
        return "Typing failed"


def read_file(path: str) -> str:
    allowed, msg = check_security("read_file", path=path)
    if not allowed:
        return msg
    try:
        with open(path, 'r') as f:
            return f.read()
    except Exception:
        return "Read failed"


def write_file(path: str, content: str) -> str:
    allowed, msg = check_security("write_file", path=path)
    if not allowed:
        return msg
    try:
        with open(path, 'w') as f:
            f.write(content)
        return f"Written to {path}"
    except Exception:
        return "Write failed"


def browse_web(url: str) -> str:
    allowed, msg = check_security("browse_web", url=url)
    if not allowed:
        return msg
    try:
        import requests
        response = requests.get(url, timeout=10)
        return f"Browsed {url}: {response.text[:500]}..."
    except Exception:
        return "Browse failed"
