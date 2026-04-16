# DeskForge - AI Desktop Agent

Transform your desktop into an intelligent assistant powered by local LLMs and computer control.

## 🚀 One-Click Setup

Get started instantly with our automated setup scripts:

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/gh4reeb/deskforge/main/setup.sh | bash
```

**Windows (PowerShell as Admin):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/gh4reeb/deskforge/main/setup.ps1" -OutFile "setup.ps1"
.\setup.ps1
```

If the repository is not already present in the current directory, the installer will clone DeskForge automatically into a `deskforge` subfolder and continue from there.

This will install all dependencies (Rust, Node.js, Python packages), start local services, and launch the app. No manual configuration needed!

## Features

- **Local AI**: Run Ollama models locally with dynamic model selection
- **Agent Orchestration**: LangGraph multi-agent system
- **Memory**: ChromaDB for RAG and long-term memory
- **Computer Control**: PyAutoGUI for desktop automation
- **Modern UI**: Svelte 5 + Shadcn-svelte + Tailwind
- **Native App**: Tauri 2 for 5-8 MB native feel
- **Self-Learning**: Automatically learns from your interactions to improve assistance
- **Security**: Built-in boundaries and permission prompts

## Example Tasks

- "Take a screenshot and click at 100,100"
- "Type 'Hello World' in the active window"
- "Read the content of my notes.txt file"
- "Write a summary to summary.txt"

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
   ```

4. Run the app

   ```bash
   npm run tauri dev
   ```

### Model Selection

During setup, the installer will detect system resources and recommend a model.
You can choose `llama3.2:3b`, `moondream`, or enter a custom Ollama model tag.
The selected model is saved to `.env` as `DESKFORGE_MODEL`.

To change models later, update `.env` or set `DESKFORGE_MODEL` before starting the backend.

   ```bash
   npm run tauri dev
   ```

## Architecture

- **Frontend**: Svelte 5 UI
- **Backend**: Python FastAPI + LangGraph agents
- **Bridge**: Rust Tauri commands
- **AI**: Ollama for local inference
- **Storage**: ChromaDB + SQLite

## 📚 Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Development Guide](docs/development.md)
