# Development Guide

## Architecture

### Frontend (Svelte)

- `src/App.svelte`: Main UI
- Uses Tauri API to invoke Rust commands

### Backend (Python)

- `agent-backend/app/main.py`: Entry point
- FastAPI server for agent orchestration
- LangGraph for multi-agent workflows

### Bridge (Rust)

- `src-tauri/src/commands.rs`: Exposes Python backend to frontend
- Uses std::process to run Python scripts

## Adding New Agents

1. Define agent in LangGraph
2. Add endpoint in main.py
3. Update commands.rs if needed
4. Modify UI to call new command

## Local LLMs

- Use Ollama for model management
- Models: llama3.2:3b for text, moondream for vision

## Memory

- ChromaDB for vector storage
- SQLite for structured data

## Security

- Agents run in sandboxed environment
- No network access except via proxy