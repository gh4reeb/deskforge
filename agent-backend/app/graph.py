from langgraph.graph import StateGraph, START, END
from langchain_ollama import ChatOllama
from .models import AgentState

try:
    llm = ChatOllama(model="llama3.2:3b", temperature=0.3)
    llm_available = True
except:
    llm_available = False

def planner_node(state: AgentState):
    # Plan the task
    if llm_available:
        prompt = f"Plan how to execute: {state.messages[-1]}"
        response = llm.invoke(prompt)
        result = response.content
    else:
        result = f"Mock plan for: {state.messages[-1]}"
    state.messages.append(result)
    return state

def executor_node(state: AgentState):
    # Execute the plan
    if llm_available:
        prompt = f"Execute based on plan: {state.messages}"
        response = llm.invoke(prompt)
        result = response.content
    else:
        result = f"Mock execution for: {state.messages}"
    state.messages.append(result)
    return state

def reviewer_node(state: AgentState):
    # Review the execution
    if llm_available:
        prompt = f"Review the result: {state.messages}"
        response = llm.invoke(prompt)
        result = response.content
    else:
        result = f"Mock review for: {state.messages}"
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