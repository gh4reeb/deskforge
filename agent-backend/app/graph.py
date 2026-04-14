from langgraph.graph import StateGraph, START, END
from langchain_ollama import ChatOllama
from .models import AgentState
from .main import take_screenshot, mouse_click, type_text, read_file, write_file

try:
    llm = ChatOllama(model="llama3.2:3b", temperature=0.3)
    llm_available = True
except:
    llm_available = False

def planner_node(state: AgentState):
    task = state.messages[0]
    if llm_available:
        prompt = f"Plan how to execute: {task}. Available tools: take_screenshot, mouse_click, type_text, read_file, write_file."
        response = llm.invoke(prompt)
        result = response.content
    else:
        result = f"Plan for: {task}"
    state.messages.append(result)
    return state

def executor_node(state: AgentState):
    plan = state.messages[-1]
    if llm_available:
        prompt = f"Execute based on plan: {plan}. Use tools if needed."
        response = llm.invoke(prompt)
        result = response.content
        # Simulate tool call
        if "screenshot" in result.lower():
            result += " " + take_screenshot()
        elif "click" in result.lower():
            result += " " + mouse_click(100, 100)  # Example
    else:
        result = f"Execute: {plan}"
    state.messages.append(result)
    return state

def reviewer_node(state: AgentState):
    execution = state.messages[-1]
    if llm_available:
        prompt = f"Review the result: {execution}"
        response = llm.invoke(prompt)
        result = response.content
    else:
        result = f"Review: {execution}"
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