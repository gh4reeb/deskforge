import os
from langgraph.graph import StateGraph, START, END
from langchain_ollama import ChatOllama
from .models import AgentState
from .tools import take_screenshot, mouse_click, type_text, read_file, write_file, browse_web


def load_env_file(path):
    if not os.path.exists(path):
        return
    while os.path.islink(path):
        path = os.path.realpath(path)
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value

root_env = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))
load_env_file(root_env)
load_env_file(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.env')))

MODEL_NAME = os.getenv("DESKFORGE_MODEL", "llama3.2:3b")

try:
    llm = ChatOllama(model=MODEL_NAME, temperature=0.3)
    llm_available = True
except Exception:
    llm_available = False


def safe_llm_invoke(prompt: str) -> str | None:
    if not llm_available:
        return None
    try:
        response = llm.invoke(prompt)
        return getattr(response, 'content', None)
    except Exception:
        return None


def planner_node(state: AgentState):
    task = state.messages[0]
    prompt = f"Plan how to execute: {task}. Available tools: take_screenshot, mouse_click, type_text, read_file, write_file."
    content = None
    try:
        content = safe_llm_invoke(prompt)
    except Exception:
        content = None
    result = content if content is not None else f"Plan for: {task}"
    state.messages.append(result)
    return state

def executor_node(state: AgentState):
    plan = state.messages[-1]
    result = plan
    if "screenshot" in plan.lower():
        result += " " + take_screenshot()
    if "click" in plan.lower():
        result += " " + mouse_click(300, 300)
    if "type" in plan.lower():
        result += " " + type_text("Hello World")
    if "read" in plan.lower():
        result += " " + read_file("example.txt")
    if "write" in plan.lower():
        result += " " + write_file("output.txt", "Sample content")
    if "browse" in plan.lower():
        result += " " + browse_web("https://example.com")
    state.messages.append(result)
    return state

def reviewer_node(state: AgentState):
    execution = state.messages[-1]
    prompt = f"Review the result: {execution}"
    content = None
    try:
        content = safe_llm_invoke(prompt)
    except Exception:
        content = None
    result = content if content is not None else f"Review: {execution}"
    state.messages.append(result)
    return state

def create_graph():
    graph = StateGraph(AgentState)
    graph.add_node("planner", planner_node)
    graph.add_node("executor", executor_node)
    graph.add_node("reviewer", reviewer_node)
    graph.add_edge(START, "planner")
    graph.add_edge("planner", "executor")
    graph.add_edge("executor", "reviewer")
    graph.add_edge("reviewer", END)
    return graph.compile()