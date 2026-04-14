#!/bin/bash

set -e

echo "Setting up DeskForge AI Desktop Agent..."

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
fi

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install dependencies
echo "Installing frontend dependencies..."
npm install

echo "Setting up Python backend..."
cd agent-backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Start services
echo "Starting Ollama and ChromaDB..."
docker-compose up -d

echo "Pulling Ollama models..."
# Assume ollama is running
# ollama pull llama3.2:3b
# ollama pull moondream

echo "Building and running the app..."
npm run tauri dev