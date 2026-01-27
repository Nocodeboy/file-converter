# ============================================
# FILE CONVERTER - MAIN SCRIPT
# ============================================
# Convert and compress files easily
# Supports: Images, Audio, Video, Documents
# ============================================
# Author: German Huertas (ghptiemblo@gmail.com)
# License: MIT
# ============================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputBase = Join-Path $scriptPath "INPUT"
$outputBase = Join-Path $scriptPath "OUTPUT"

# Load modules
. "$scriptPath\scripts\convert-images.ps1"
. "$scriptPath\scripts\convert-audio.ps1"
. "$scriptPath\scripts\convert-video.ps1"
. "$scriptPath\scripts\convert-documents.ps1"
. "$scriptPath\scripts\compress-images.ps1"
. "$scriptPath\scripts\compress-audio.ps1"
. "$scriptPath\scripts\compress-video.ps1"

# Utility function to check available disk space
function Test-DiskSpace {
    param(
        [string]$Path,
        [long]$RequiredMB = 100
    )
    try {
        $drive = (Get-Item $Path).PSDrive.Name
        $driveInfo = Get-PSDrive -Name $drive
        $freeSpaceMB = [math]::Round($driveInfo.Free / 1MB, 0)

        if ($freeSpaceMB -lt $RequiredMB) {
            Write-Host ""
            Write-Host "  [WARNING] Low disk space: ${freeSpaceMB}MB available (need ${RequiredMB}MB)" -ForegroundColor Yellow
            Write-Host "  Free up space before continuing to avoid conversion failures." -ForegroundColor Yellow
            Write-Host ""
            return $false
        }
        return $true
    }
    catch {
        # If we can't check, assume it's OK
        return $true
    }
}

# Function to confirm before processing
function Confirm-Action {
    param([string]$Message)
    $confirm = Read-Host "  $Message (Y/N)"
    return ($confirm.ToUpper() -eq "Y")
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  =================================================================" -ForegroundColor Cyan
    Write-Host "                                                                   " -ForegroundColor Cyan
    Write-Host "   ######  ### ##       ########                                   " -ForegroundColor Magenta
    Write-Host "   ##       ## ##       ##                                         " -ForegroundColor Magenta
    Write-Host "   #####    ## ##       #####                                      " -ForegroundColor Magenta
    Write-Host "   ##       ## ##       ##                                         " -ForegroundColor Magenta
    Write-Host "   ##      ### ######## ########                                   " -ForegroundColor Magenta
    Write-Host "                                                                   " -ForegroundColor Cyan
    Write-Host "    ######  #######  ##    ## ##     ## ######## ########          " -ForegroundColor Yellow
    Write-Host "   ##       ##   ##  ###   ## ##     ## ##       ##   ##           " -ForegroundColor Yellow
    Write-Host "   ##       ##   ##  ## ## ## ##     ## #####    ######            " -ForegroundColor Yellow
    Write-Host "   ##       ##   ##  ##   ### ##   ##   ##       ##  ##            " -ForegroundColor Yellow
    Write-Host "    ######  #######  ##    ##   ###     ######## ##   ##           " -ForegroundColor Yellow
    Write-Host "                                                                   " -ForegroundColor Cyan
    Write-Host "  =================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "    MAIN MENU                                                      " -ForegroundColor White
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    [1] IMAGES     - Convert or Compress" -ForegroundColor White
    Write-Host "    [2] AUDIO      - Convert or Compress" -ForegroundColor White
    Write-Host "    [3] VIDEO      - Convert or Compress" -ForegroundColor White
    Write-Host "    [4] DOCUMENTS  - Convert formats" -ForegroundColor White
    Write-Host ""
    Write-Host "    [5] Open INPUT folder" -ForegroundColor DarkCyan
    Write-Host "    [6] Open OUTPUT folder" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "    [0] Exit" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  -----------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-SubMenu {
    param([string]$Type)
    Write-Host ""
    Write-Host "  What do you want to do with $Type ?" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host "    [C] CONVERT  - Change format" -ForegroundColor White
    Write-Host "    [O] OPTIMIZE - Compress/reduce size" -ForegroundColor White
    Write-Host "    [B] BACK     - Main menu" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-FileCount {
    $imgCount = (Get-ChildItem -Path "$inputBase\images" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $audCount = (Get-ChildItem -Path "$inputBase\audio" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $vidCount = (Get-ChildItem -Path "$inputBase\video" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $docCount = (Get-ChildItem -Path "$inputBase\documents" -File -ErrorAction SilentlyContinue | Measure-Object).Count

    Write-Host "  Files in INPUT:" -ForegroundColor Cyan
    Write-Host "     Images: $imgCount | Audio: $audCount | Video: $vidCount | Docs: $docCount" -ForegroundColor Gray
    Write-Host ""
}

function Pause-Script {
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main loop
do {
    Show-Header
    Show-FileCount
    Show-MainMenu

    $option = Read-Host "  Select an option"

    switch ($option) {
        "1" {
            # IMAGES
            Show-Header
            Show-SubMenu "IMAGES"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Host "  IMAGE CONVERSION" -ForegroundColor Magenta
                    Show-ImageFormats
                    $format = Read-Host "  Choose output format"
                    if ($format -ne "") {
                        Convert-Images -InputFolder "$inputBase\images" -OutputFolder "$outputBase\images" -OutputFormat $format
                    }
                    Pause-Script
                }
                "O" {
                    Show-Header
                    Write-Host "  IMAGE COMPRESSION" -ForegroundColor Magenta
                    Show-ImageCompressionLevels
                    $level = Read-Host "  Choose compression level (1-4)"
                    
                    Write-Host ""
                    Write-Host "  Output format:" -ForegroundColor Cyan
                    Write-Host "    [1] WEBP (best compression)" -ForegroundColor White
                    Write-Host "    [2] JPG (most compatible)" -ForegroundColor White
                    $formatComp = Read-Host "  Choose format"
                    $outputFormat = if ($formatComp -eq "2") { "jpg" } else { "webp" }
                    
                    if ($level -ne "") {
                        Compress-Images -InputFolder "$inputBase\images" -OutputFolder "$outputBase\images" -Level $level -OutputFormat $outputFormat
                    }
                    Pause-Script
                }
            }
        }
        "2" {
            # AUDIO
            if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
                Write-Host "  [X] FFmpeg not installed." -ForegroundColor Red
                Pause-Script
                continue
            }
            
            Show-Header
            Show-SubMenu "AUDIO"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Host "  AUDIO CONVERSION" -ForegroundColor Magenta
                    Show-AudioFormats
                    $format = Read-Host "  Choose output format"
                    if ($format -ne "") {
                        Convert-Audio -InputFolder "$inputBase\audio" -OutputFolder "$outputBase\audio" -OutputFormat $format
                    }
                    Pause-Script
                }
                "O" {
                    Show-Header
                    Write-Host "  AUDIO COMPRESSION" -ForegroundColor Magenta

                    # First, select output format
                    Show-AudioOutputFormats
                    $outputFormat = Read-Host "  Choose output format (1-4)"
                    if ($outputFormat -eq "") { $outputFormat = "1" }

                    # Then, select compression level (skip for FLAC which is lossless)
                    if ($outputFormat -eq "4") {
                        Write-Host ""
                        Write-Host "  FLAC is lossless - no compression level needed" -ForegroundColor DarkGray
                        $level = "1"  # Dummy value, ignored for FLAC
                    } else {
                        $formatName = if ($outputFormat -eq "1") { "MP3" } elseif ($outputFormat -eq "2") { "AAC" } else { "OGG" }
                        Show-AudioCompressionLevels -Format $formatName
                        $level = Read-Host "  Choose compression level (1-4)"
                    }

                    if ($level -ne "") {
                        Compress-Audio -InputFolder "$inputBase\audio" -OutputFolder "$outputBase\audio" -Level $level -OutputFormat $outputFormat
                    }
                    Pause-Script
                }
            }
        }
        "3" {
            # VIDEO
            if (-not (Get-Command "ffmpeg" -ErrorAction SilentlyContinue)) {
                Write-Host "  [X] FFmpeg not installed." -ForegroundColor Red
                Pause-Script
                continue
            }
            
            Show-Header
            Show-SubMenu "VIDEO"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Host "  VIDEO CONVERSION" -ForegroundColor Magenta

                    # Check disk space before video conversion (require 2GB minimum)
                    if (-not (Test-DiskSpace -Path $outputBase -RequiredMB 2048)) {
                        if (-not (Confirm-Action "Continue anyway?")) {
                            Pause-Script
                            break
                        }
                    }

                    Show-VideoFormats
                    $format = Read-Host "  Choose output format"
                    if ($format -ne "") {
                        Convert-Video -InputFolder "$inputBase\video" -OutputFolder "$outputBase\video" -OutputFormat $format
                    }
                    Pause-Script
                }
                "O" {
                    Show-Header
                    Write-Host "  VIDEO COMPRESSION" -ForegroundColor Magenta

                    # Check disk space before video compression (require 2GB minimum)
                    if (-not (Test-DiskSpace -Path $outputBase -RequiredMB 2048)) {
                        if (-not (Confirm-Action "Continue anyway?")) {
                            Pause-Script
                            break
                        }
                    }

                    Show-VideoCompressionLevels
                    $level = Read-Host "  Choose compression level (1-4)"

                    Write-Host ""
                    do {
                        $resize = Read-Host "  Downscale to 720p? (Y/N)"
                        $resizeUpper = $resize.ToUpper()
                        if ($resizeUpper -ne "Y" -and $resizeUpper -ne "N" -and $resize -ne "") {
                            Write-Host "  [X] Please enter Y or N" -ForegroundColor Red
                        }
                    } while ($resizeUpper -ne "Y" -and $resizeUpper -ne "N" -and $resize -ne "")

                    $resize720 = ($resizeUpper -eq "Y")

                    if ($level -ne "") {
                        Compress-Video -InputFolder "$inputBase\video" -OutputFolder "$outputBase\video" -Level $level -Resize720 $resize720
                    }
                    Pause-Script
                }
            }
        }
        "4" {
            # DOCUMENTS
            if (-not (Get-Command "pandoc" -ErrorAction SilentlyContinue)) {
                Write-Host "  [X] Pandoc not installed." -ForegroundColor Red
                Pause-Script
                continue
            }
            Show-Header
            Write-Host "  DOCUMENT CONVERSION" -ForegroundColor Magenta
            Show-DocumentFormats
            $format = Read-Host "  Choose output format"
            if ($format -ne "") {
                Convert-Documents -InputFolder "$inputBase\documents" -OutputFolder "$outputBase\documents" -OutputFormat $format
            }
            Pause-Script
        }
        "5" {
            Start-Process explorer.exe $inputBase
        }
        "6" {
            Start-Process explorer.exe $outputBase
        }
        "0" {
            Write-Host ""
            Write-Host "  Goodbye!" -ForegroundColor Cyan
            Write-Host ""
            exit
        }
        default {
            Write-Host "  [X] Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
