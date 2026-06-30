$ErrorActionPreference = "Stop"

# --- 1. Git Installation Check ---
Write-Host "Verifying prerequisites..." -ForegroundColor Cyan
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Git is missing. Installing via Windows Package Manager (winget)..." -ForegroundColor Yellow
    
    # Install Git silently
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    
    # Refresh the environment path in this session so we can use Git immediately
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Final safety check
    if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
        Write-Host "Git installed, but Windows needs a moment to register it. Please close this and run the shortcut again." -ForegroundColor Red
        Pause
        exit
    }
    Write-Host "Git installed successfully!" -ForegroundColor Green
}

# --- 2. Set Up Paths ---
$WorkingDir = $PSScriptRoot
if (-not $WorkingDir) { $WorkingDir = Get-Location }

$RepoUrl = "https://github.com/Raphire/Win11Debloat.git"
$DebloatDir = Join-Path $WorkingDir "Win11Debloat"

Write-Host "Syncing Win11Debloat with GitHub..." -ForegroundColor Cyan

# --- 3. Clone or Pull ---
if (-not (Test-Path (Join-Path $DebloatDir ".git"))) {
    Write-Host "Local repository not found. Cloning the latest version..." -ForegroundColor Yellow
    git clone $RepoUrl $DebloatDir
} else {
    Write-Host "Local repository found. Pulling latest updates..." -ForegroundColor Yellow
    Set-Location $DebloatDir
    git pull
}

Write-Host "Sync complete!" -ForegroundColor Green
Start-Sleep -Seconds 1

# --- 4. Launch Win11Debloat ---
$RunBat = Join-Path $DebloatDir "Run.bat"
if (Test-Path $RunBat) {
    Write-Host "Starting Win11Debloat..." -ForegroundColor Cyan
    Start-Process -FilePath $RunBat -WorkingDirectory $DebloatDir
} else {
    Write-Host "Error: Could not find Run.bat. The clone or pull might have failed." -ForegroundColor Red
    Pause
}