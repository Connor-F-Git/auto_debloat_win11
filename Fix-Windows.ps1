$ErrorActionPreference = "Continue" # Allows us to handle Git errors gracefully instead of hard-crashing

# --- 1. Git Installation Check ---
Write-Host "Verifying prerequisites..." -ForegroundColor Cyan
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Git is missing. Installing via Windows Package Manager (winget)..." -ForegroundColor Yellow
    
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
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

# --- 3. Clone or Pull (With Error Handling) ---
if (-not (Test-Path (Join-Path $DebloatDir ".git"))) {
    
    Write-Host "Local folder missing. Downloading fresh from GitHub..." -ForegroundColor Yellow
    git clone $RepoUrl $DebloatDir
    
    # Check if the download actually succeeded
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nCRITICAL ERROR: Failed to download Win11Debloat." -ForegroundColor Red
        Write-Host "Please check your internet connection or see if GitHub is down." -ForegroundColor Red
        Pause
        exit
    }
    
} else {
    
    Write-Host "Local repository found. Checking GitHub for updates..." -ForegroundColor Yellow
    Set-Location $DebloatDir
    git pull
    
    # Check if the update succeeded
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nWARNING: Could not connect to GitHub to check for updates." -ForegroundColor DarkYellow
        Write-Host "Proceeding with your existing, older local version in 3 seconds..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 3
    }
}

Write-Host "`nSync phase complete!" -ForegroundColor Green
Start-Sleep -Seconds 1

# --- 4. Launch Win11Debloat ---
$RunBat = Join-Path $DebloatDir "Run.bat"
if (Test-Path $RunBat) {
    Write-Host "Starting Win11Debloat..." -ForegroundColor Cyan
    Start-Process -FilePath $RunBat -WorkingDirectory $DebloatDir
} else {
    # This is a final safety net in case the folder exists but is corrupted/empty
    Write-Host "Error: Could not find Run.bat." -ForegroundColor Red
    Write-Host "The Win11Debloat folder might be corrupted. Try deleting the folder and running this shortcut again." -ForegroundColor Red
    Pause
}
