# setup.ps1 - One-click setup for DeskForge on Windows

Write-Host "Setting up DeskForge AI Desktop Agent on Windows..."

$CurrentDir = Get-Location
$RepoRoot = $null
if (Test-Path (Join-Path $CurrentDir "package.json")) {
    $RepoRoot = $CurrentDir
} elseif (Test-Path (Join-Path $CurrentDir "deskforge\package.json")) {
    $RepoRoot = Join-Path $CurrentDir "deskforge"
}

if (-not $RepoRoot) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "No DeskForge repository found and git is not installed."
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

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Rust..."
    $rustInstaller = Join-Path $env:TEMP "rustup-init.exe"
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $rustInstaller
    Start-Process -FilePath $rustInstaller -ArgumentList "/quiet", "/no-modify-path" -Wait
    Remove-Item $rustInstaller
    $env:Path += ";$env:USERPROFILE\.cargo\bin"
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id OpenJS.NodeJS -e --accept-package-agreements --accept-source-agreements
    } else {
        Write-Error "Node.js is required. Install it manually from https://nodejs.org/."
        exit 1
    }
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Ollama..."
    $installer = Join-Path $env:TEMP "OllamaSetup.exe"
    Invoke-WebRequest -Uri "https://ollama.ai/download/OllamaSetup.exe" -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList "/S" -Wait
    Remove-Item $installer
}

Write-Host "Installing frontend dependencies..."
if (Test-Path "$RepoRoot\node_modules") {
    Write-Host "Frontend dependencies already installed."
} else {
    npm install
}

Write-Host "Setting up Python backend..."
Set-Location "$RepoRoot\agent-backend"
if (-not (Test-Path "venv")) {
    python -m venv venv
}
& "$RepoRoot\agent-backend\venv\Scripts\Activate.ps1"
pip install --upgrade pip
pip install -r requirements.txt
Set-Location $RepoRoot

$EnvFile = Join-Path $RepoRoot ".env"
$ModelName = $null
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^DESKFORGE_MODEL=(.+)$') { $ModelName = $Matches[1] }
    }
}

if (-not $ModelName) {
    Write-Host "Select an Ollama model to install:"
    Write-Host "  1) llama3.2:3b"
    Write-Host "  2) moondream"
    Write-Host "  3) custom model"
    $choice = Read-Host "Choice (default 1)"
    switch ($choice) {
        "2" { $ModelName = "moondream" }
        "3" { $ModelName = Read-Host "Enter Ollama model tag" }
        default { $ModelName = "llama3.2:3b" }
    }
    if (-not $ModelName) { $ModelName = "llama3.2:3b" }
    "DESKFORGE_MODEL=$ModelName" | Set-Content $EnvFile
    Write-Host "Selected model: $ModelName"
} else {
    Write-Host "Using existing model from .env: $ModelName"
}

Write-Host "Starting Ollama and Chroma..."
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is required. Install Docker Desktop and retry."
    exit 1
}

$composeCommand = $null
try {
    docker compose version | Out-Null
    $composeCommand = "docker compose"
} catch {
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        $composeCommand = "docker-compose"
    }
}

if (-not $composeCommand) {
    Write-Error "Docker Compose is not available. Ensure Docker Desktop is installed."
    exit 1
}

& $composeCommand up -d

Write-Host "Pulling Ollama model $ModelName..."
try {
    if (ollama list | Select-String -SimpleMatch $ModelName) {
        Write-Host "Ollama model $ModelName already installed."
    } else {
        ollama pull $ModelName
    }
} catch {
    ollama pull $ModelName
}

Write-Host "Starting Python backend..."
$running = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'run.py' }
if ($running) {
    Write-Host "Python backend appears to already be running."
} else {
    Start-Process -FilePath "$RepoRoot\agent-backend\venv\Scripts\python.exe" -ArgumentList "run.py" -WorkingDirectory "$RepoRoot\agent-backend" -NoNewWindow
}

Write-Host "Setup complete! Run 'npm run tauri dev' to start the app."