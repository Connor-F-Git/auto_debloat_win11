$ErrorActionPreference = "Continue"

# --- 1. Bulletproof Git Installation (With Progress Bar) ---
$GitExePath = "C:\Program Files\Git\cmd\git.exe"

if (-not (Get-Command "git" -ErrorAction SilentlyContinue) -and -not (Test-Path $GitExePath)) {
    Write-Host "Git is missing. Downloading the standalone installer..." -ForegroundColor Yellow
    
    # We keep this silent to ensure the download doesn't throttle your internet speed
    $OriginalProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    
    # Fetch the latest Git for Windows 64-bit installer directly from GitHub
    $GitReleaseApi = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    try {
        $GitRelease = Invoke-RestMethod -Uri $GitReleaseApi -UseBasicParsing
        $GitDownloadUrl = ($GitRelease.assets | Where-Object { $_.name -match "Git-.*-64-bit\.exe" }).browser_download_url
        
        $GitInstallerTemp = Join-Path $env:TEMP "GitInstaller.exe"
        Write-Host "Downloading Git... (This usually takes 5-10 seconds)" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $GitDownloadUrl -OutFile $GitInstallerTemp -UseBasicParsing
        
        Write-Host "Installing Git. A progress window should appear..." -ForegroundColor Cyan
        
        # CHANGED: Replaced /VERYSILENT with /SILENT so the progress bar is visible
        Start-Process -FilePath $GitInstallerTemp -ArgumentList "/SILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES" -Wait -NoNewWindow
        
        Remove-Item -Path $GitInstallerTemp -Force
    } catch {
        Write-Host "`nCRITICAL ERROR: Failed to download or install Git directly." -ForegroundColor Red
        Pause
        exit
    }
    $ProgressPreference = $OriginalProgress
}

# --- 2. Force Git Recognition Instantly ---
# Attempt to refresh the session path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# If Windows still hasn't registered 'git' globally, force an alias to the absolute path
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    if (Test-Path $GitExePath) {
        Set-Alias git $GitExePath
    } else {
        Write-Host "Git installation failed or installed to an unknown directory." -ForegroundColor Red
        Pause
        exit
    }
}

Write-Host "Git is ready!" -ForegroundColor Green

# --- 3. Set Up Paths ---
$WorkingDir = $PSScriptRoot
if (-not $WorkingDir) { $WorkingDir = Get-Location }

$RepoUrl = "https://github.com/Raphire/Win11Debloat.git"
$DebloatDir = Join-Path $WorkingDir "Win11Debloat"

Write-Host "Syncing Win11Debloat with GitHub..." -ForegroundColor Cyan

# --- 4. Clone or Pull (With Error Handling) ---
if (-not (Test-Path (Join-Path $DebloatDir ".git"))) {
    
    Write-Host "Local folder missing. Downloading fresh from GitHub..." -ForegroundColor Yellow
    git clone $RepoUrl $DebloatDir
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nCRITICAL ERROR: Failed to download Win11Debloat." -ForegroundColor Red
        Pause
        exit
    }
    
} else {
    
    Write-Host "Local repository found. Checking GitHub for updates..." -ForegroundColor Yellow
    Set-Location $DebloatDir
    git pull
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nWARNING: Could not connect to GitHub to check for updates." -ForegroundColor DarkYellow
        Write-Host "Proceeding with your existing local version in 3 seconds..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 3
    }
}

Write-Host "`nSync phase complete!" -ForegroundColor Green
Start-Sleep -Seconds 1

# --- 5. Launch Win11Debloat ---
$RunBat = Join-Path $DebloatDir "Run.bat"
if (Test-Path $RunBat) {
    Write-Host "Starting Win11Debloat..." -ForegroundColor Cyan
    Start-Process -FilePath $RunBat -WorkingDirectory $DebloatDir
} else {
    Write-Host "Error: Could not find Run.bat." -ForegroundColor Red
    Pause
}
