# Architecture

## Overview

DeskForge is a local AI desktop agent built with Tauri, Python, and LangGraph. It allows users to interact with their computer using natural language commands, with built-in safety boundaries.

## Components

### Frontend (Svelte + Tauri)
- **UI**: Svelte 5 for reactive interface
- **Bridge**: Tauri Rust backend for secure system access
- **Communication**: HTTP calls to Python backend

### Backend (Python + FastAPI)
- **API**: FastAPI server handling agent requests
- **Agent**: LangGraph multi-agent system (Planner → Executor → Reviewer)
- **Tools**: Safe implementations of computer control functions
- **Memory**: ChromaDB for conversation history and RAG

### Services
- **Ollama**: Local LLM inference (Llama-3.2 3B, Moondream2)
- **ChromaDB**: Vector database for memory

## Data Flow

1. User inputs task in UI
2. Tauri sends HTTP request to Python backend
3. LangGraph processes task through agents
4. Tools execute actions with permission checks
5. Result returned with screenshot
6. Memory stored for future context

## Security Model

- **Tool Whitelist**: Only approved tools can be used
- **Path Restrictions**: Forbidden directories blocked
- **Permission Prompts**: User approval required for actions
- **Sandbox**: No direct system access without validation