#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd || true)"
CURRENT_DIR="$(pwd)"
ROOT_DIR=""

echo "Setting up DeskForge AI Desktop Agent..."

if [[ -f "$CURRENT_DIR/package.json" ]]; then
    ROOT_DIR="$CURRENT_DIR"
elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/package.json" ]]; then
    ROOT_DIR="$SCRIPT_DIR"
elif [[ -f "$CURRENT_DIR/deskforge/package.json" ]]; then
    ROOT_DIR="$CURRENT_DIR/deskforge"
fi

if [[ -z "$ROOT_DIR" ]]; then
    if ! command -v git &> /dev/null; then
        echo "Error: No DeskForge repository found in the current directory and git is not installed."
        exit 1
    fi

    INSTALL_DIR="$CURRENT_DIR/deskforge"
    echo "No repository files found in $CURRENT_DIR."
    echo "Cloning DeskForge into $INSTALL_DIR ..."
    git clone https://github.com/gh4reeb/deskforge.git "$INSTALL_DIR"
    ROOT_DIR="$INSTALL_DIR"
fi

cd "$ROOT_DIR"
echo "Using repository root: $ROOT_DIR"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "Detected OS: $OS"

apt_update_retry() {
    local attempts=0
    local max_attempts=3
    until sudo apt-get update -o Acquire::Retries=3; do
        attempts=$((attempts + 1))
        if [[ "$attempts" -ge "$max_attempts" ]]; then
            echo "apt-get update failed after $attempts attempts."
            echo "Please check your network or Ubuntu mirror settings and try again."
            exit 1
        fi
        echo "Retrying apt-get update ($attempts/$max_attempts)..."
        sudo rm -rf /var/lib/apt/lists/*
        sleep 2
    done
}

ensure_apt_update() {
    if [[ "$OS" == "linux" ]]; then
        apt_update_retry
    fi
}

if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    if [[ "$OS" == "linux" ]]; then
        ensure_apt_update
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        brew install node@18
    elif [[ "$OS" == "windows" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
fi

if [[ "$OS" == "linux" ]]; then
    ensure_apt_update
    if ! command -v pkg-config >/dev/null 2>&1 || ! pkg-config --exists glib-2.0 >/dev/null 2>&1; then
        echo "Installing Linux dependencies required for Tauri builds..."
        sudo apt-get install -y pkg-config libglib2.0-dev libgtk-4-dev libwebkit2gtk-4.0-dev libayatana-appindicator3-dev libsecret-1-dev build-essential
    fi
fi

if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://ollama.ai/install.sh | sh
    elif [[ "$OS" == "macos" ]]; then
        brew install ollama
    elif [[ "$OS" == "windows" ]]; then
        echo "Please install Ollama manually on Windows: https://ollama.ai/download"
        exit 1
    fi
fi

echo "Installing frontend dependencies..."
if [[ -d "node_modules" ]]; then
    echo "Frontend dependencies already installed."
else
    npm install
fi

echo "Setting up Python backend..."
cd agent-backend
if [[ ! -d "venv" ]]; then
    python3 -m venv venv
fi
if [[ "$OS" == "windows" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
pip install --upgrade pip
pip install -r requirements.txt
deactivate || true
cd ..

if [[ -f ".env" ]]; then
    source .env
fi

if [[ "$OS" == "linux" && -r /proc/meminfo ]]; then
    MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_GB=$((MEM_KB / 1024 / 1024))
else
    MEM_GB=0
fi

if [[ "$MEM_GB" -ge 12 ]]; then
    RECOMMENDED_MODEL="llama3.2:3b"
else
    RECOMMENDED_MODEL="moondream"
fi

if [[ -n "${DESKFORGE_MODEL:-}" ]]; then
    MODEL_NAME="$DESKFORGE_MODEL"
    echo "Using previously selected model from .env: $MODEL_NAME"
else
    MODEL_PROMPT="Select an Ollama model to install:\n  1) llama3.2:3b\n  2) moondream\n  3) custom model name"
    echo "Detected approximately $MEM_GB GB RAM. Recommended model: $RECOMMENDED_MODEL"
    echo -e "$MODEL_PROMPT"
    if [[ -t 0 ]]; then
        read -r model_choice
    else
        model_choice=1
    fi
    case "$model_choice" in
        2)
            MODEL_NAME="moondream"
            ;;
        3)
            if [[ -t 0 ]]; then
                read -r -p "Enter Ollama model tag: " custom_model
            else
                custom_model=""
            fi
            MODEL_NAME="${custom_model:-$RECOMMENDED_MODEL}"
            ;;
        *)
            MODEL_NAME="llama3.2:3b"
            ;;
    esac
fi

if [[ -z "${MODEL_NAME:-}" ]]; then
    MODEL_NAME="$RECOMMENDED_MODEL"
fi

printf "DESKFORGE_MODEL=%s\n" "$MODEL_NAME" > .env
echo "Selected model: $MODEL_NAME"

echo "Starting Ollama and Chroma..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose up -d
else
    if ! command -v docker >/dev/null 2>&1; then
        if [[ "$OS" == "linux" ]]; then
            echo "Installing Docker..."
            ensure_apt_update
            sudo apt-get install -y docker.io
            sudo systemctl enable --now docker || true
        else
            echo "Error: Docker is required but not installed. Install Docker and retry."
            exit 1
        fi
    fi

    if ! docker compose version >/dev/null 2>&1; then
        if [[ "$OS" == "linux" ]]; then
            echo "Installing Docker Compose support..."
            ensure_apt_update
            if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
                sudo apt-get install -y docker-compose-plugin
            elif apt-cache show docker-compose >/dev/null 2>&1; then
                sudo apt-get install -y docker-compose
            else
                if command -v python3 >/dev/null 2>&1; then
                    python3 -m pip install --user docker-compose
                fi
            fi
        fi
    fi

    if command -v docker compose >/dev/null 2>&1; then
        docker compose up -d
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose up -d
    else
        echo "Error: Docker Compose is not available after install. Install docker-compose or docker-compose-plugin and retry."
        exit 1
    fi
fi

echo "Pulling Ollama model $MODEL_NAME..."
if ollama list | grep -qF "$MODEL_NAME"; then
    echo "Ollama model $MODEL_NAME is already installed."
else
    ollama pull "$MODEL_NAME"
fi

echo "Starting Python backend..."
cd agent-backend
if pgrep -f "python.*run.py" >/dev/null 2>&1; then
    echo "Python backend already running."
else
    if [[ "$OS" == "windows" ]]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    nohup python run.py > backend.log 2>&1 &
    deactivate || true
fi
cd ..

echo "Setup complete! Run 'npm run tauri dev' to start the app."