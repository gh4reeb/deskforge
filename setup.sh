#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd || true)"
CURRENT_DIR="$(pwd)"
ROOT_DIR=""

echo "Setting up DeskForge AI Desktop Agent..."

# If the installer is being run directly from the repo, use that path.
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

# Detect OS
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

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        brew install node@18
    elif [[ "$OS" == "windows" ]]; then
        # Assume WSL, use apt
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
fi

# Install Ollama if not present
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

# Install additional tools
echo "Do you want to install network scanning tools (nmap)? (y/n)"
read -r install_nmap
if [[ "$install_nmap" == "y" ]]; then
    if [[ "$OS" == "linux" ]]; then
        sudo apt-get install -y nmap
    elif [[ "$OS" == "macos" ]]; then
        brew install nmap
    fi
fi

# Install dependencies
echo "Installing frontend dependencies..."
npm install

echo "Setting up Python backend..."
cd agent-backend
python3 -m venv venv
if [[ "$OS" == "windows" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
pip install -r requirements.txt
cd ..

# Start services
echo "Starting Ollama and Chroma..."
docker-compose up -d

echo "Pulling Ollama models..."
sleep 5  # Wait for Ollama to start
ollama pull llama3.2:3b
ollama pull moondream

echo "Starting Python backend..."
cd agent-backend
if [[ "$OS" == "windows" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi
nohup python run.py > backend.log 2>&1 &
cd ..

echo "Setup complete! Run 'npm run tauri dev' to start the app."