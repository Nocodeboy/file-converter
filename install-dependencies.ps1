# ============================================
# DEPENDENCY INSTALLER
# ============================================
# Run as Administrator to install:
# - FFmpeg (video/audio)
# - ImageMagick (images)
# - Pandoc (documents)
# ============================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           DEPENDENCY INSTALLER                              ║" -ForegroundColor Cyan
Write-Host "║           File Converter System                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Some installations may require administrator privileges." -ForegroundColor Yellow
    Write-Host "   If any installation fails, please run this script as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Function to check if a command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to install with winget
function Install-WithWinget($packageId, $name) {
    Write-Host "📦 Installing $name..." -ForegroundColor Yellow
    try {
        winget install --id $packageId --accept-package-agreements --accept-source-agreements -e
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $name installed successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "❌ Error installing $name" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error installing $name : $_" -ForegroundColor Red
        return $false
    }
}

Write-Host "🔍 Checking installed dependencies..." -ForegroundColor Cyan
Write-Host ""

# --- FFmpeg ---
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
if (Test-Command "ffmpeg") {
    $version = (ffmpeg -version 2>&1 | Select-Object -First 1)
    Write-Host "✅ FFmpeg is already installed" -ForegroundColor Green
    Write-Host "   $version" -ForegroundColor DarkGray
}
else {
    Install-WithWinget "Gyan.FFmpeg" "FFmpeg"
}

# --- ImageMagick ---
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
if (Test-Command "magick") {
    $version = (magick -version 2>&1 | Select-Object -First 1)
    Write-Host "✅ ImageMagick is already installed" -ForegroundColor Green
    Write-Host "   $version" -ForegroundColor DarkGray
}
else {
    Install-WithWinget "ImageMagick.ImageMagick" "ImageMagick"
}

# --- Pandoc ---
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
if (Test-Command "pandoc") {
    $version = (pandoc --version 2>&1 | Select-Object -First 1)
    Write-Host "✅ Pandoc is already installed" -ForegroundColor Green
    Write-Host "   $version" -ForegroundColor DarkGray
}
else {
    Install-WithWinget "JohnMacFarlane.Pandoc" "Pandoc"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "🎉 Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Close and reopen PowerShell for changes to take effect." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
