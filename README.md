# DeskForge - AI Desktop Agent

Transform your desktop into an intelligent assistant powered by local LLMs and computer control.

## Features

- **Local AI**: Run Llama-3.2 3B and Moondream2 locally with Ollama
- **Agent Orchestration**: LangGraph multi-agent system
- **Memory**: ChromaDB for RAG and long-term memory
- **Computer Control**: PyAutoGUI for desktop automation
- **Modern UI**: Svelte 5 + Shadcn-svelte + Tailwind
- **Native App**: Tauri 2 for 5-8 MB native feel

## Quick Start

### Prerequisites

- Rust 1.60+
- Node.js 18+
- Python 3.8+
- Ollama

### Setup

1. Clone the repo

2. Install dependencies

   ```bash
   # Frontend
   npm install

   # Backend
   cd agent-backend
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Start services

   ```bash
   docker-compose up -d
   ollama pull llama3.2:3b
   ollama pull moondream
   ```

4. Run the app

   ```bash
   npm run tauri dev
   ```

## Architecture

- **Frontend**: Svelte 5 UI
- **Backend**: Python FastAPI + LangGraph agents
- **Bridge**: Rust Tauri commands
- **AI**: Ollama for local inference
- **Storage**: ChromaDB + SQLite

## Contributing

See CONTRIBUTING.md
