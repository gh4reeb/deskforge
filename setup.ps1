# setup.ps1 - One-click setup for DeskForge on Windows

Write-Host "Setting up DeskForge AI Desktop Agent on Windows..."

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator for some installations."
    exit 1
}

$CurrentDir = Get-Location
$RepoRoot = $null
if (Test-Path "$CurrentDir\package.json") {
    $RepoRoot = $CurrentDir
} elseif (Test-Path "$CurrentDir\deskforge\package.json") {
    $RepoRoot = Join-Path $CurrentDir "deskforge"
}

if (-not $RepoRoot) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Error: No DeskForge repository found in the current directory and git is not installed."
        exit 1
    }

    $InstallDir = Join-Path $CurrentDir "deskforge"
    Write-Host "No repository files found in $CurrentDir."
    Write-Host "Cloning DeskForge into $InstallDir ..."
    git clone https://github.com/gh4reeb/deskforge.git $InstallDir
    $RepoRoot = $InstallDir
}

Set-Location $RepoRoot
Write-Host "Using repository root: $RepoRoot"

# Install Rust if not present
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rust..."
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "rustup-init.exe"
    Start-Process -FilePath "rustup-init.exe" -ArgumentList "/quiet", "/no-modify-path" -Wait
    Remove-Item "rustup-init.exe"
    $env:Path += ";$env:USERPROFILE\.cargo\bin"
}

# Install Node.js if not present
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..."
    winget install OpenJS.NodeJS
}

# Install Ollama if not present
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Ollama..."
    Invoke-WebRequest -Uri "https://ollama.ai/download/OllamaSetup.exe" -OutFile "OllamaSetup.exe"
    Start-Process -FilePath "OllamaSetup.exe" -ArgumentList "/S" -Wait
    Remove-Item "OllamaSetup.exe"
}

# Install dependencies
Write-Host "Installing frontend dependencies..."
npm install

# Setup Python backend
Write-Host "Setting up Python backend..."
Set-Location "$RepoRoot\agent-backend"
python -m venv venv
& "$RepoRoot\agent-backend\venv\Scripts\Activate.ps1"
pip install -r requirements.txt
Set-Location $RepoRoot

# Start services
Write-Host "Starting Ollama and Chroma..."
docker-compose up -d

# Pull models
Write-Host "Pulling Ollama models..."
Start-Sleep -Seconds 5
ollama pull llama3.2:3b
ollama pull moondream

# Start backend
Write-Host "Starting Python backend..."
Set-Location "$RepoRoot\agent-backend"
Start-Process -FilePath "python" -ArgumentList "run.py" -NoNewWindow
Set-Location $RepoRoot

Write-Host "Setup complete! Run 'npm run tauri dev' to start the app."