# ============================================
# FILE CONVERTER - MAIN SCRIPT
# ============================================
# Convert and compress files easily
# Supports: Images, Audio, Video, Documents
# ============================================
# Author: German Huertas (github.com/nocodeboy)
# License: MIT
# ============================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Paths
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputBase = Join-Path $scriptPath "INPUT"
$outputBase = Join-Path $scriptPath "OUTPUT"

# Load modules
. "$scriptPath\scripts\utils.ps1"
. "$scriptPath\scripts\convert-images.ps1"
. "$scriptPath\scripts\convert-audio.ps1"
. "$scriptPath\scripts\convert-video.ps1"
. "$scriptPath\scripts\convert-documents.ps1"
. "$scriptPath\scripts\compress-images.ps1"
. "$scriptPath\scripts\compress-audio.ps1"
. "$scriptPath\scripts\compress-video.ps1"

function Show-MainMenu {
    Write-Log "  -----------------------------------------------------------------" "INFO" "DarkGray"
    Write-Log "    MAIN MENU                                                      " "INFO" "White"
    Write-Log "  -----------------------------------------------------------------" "INFO" "DarkGray"
    Write-Log "" "" "White"
    Write-Log "    [1] IMAGES     - Convert or Compress" "INFO" "White"
    Write-Log "    [2] AUDIO      - Convert or Compress" "INFO" "White"
    Write-Log "    [3] VIDEO      - Convert or Compress" "INFO" "White"
    Write-Log "    [4] DOCUMENTS  - Convert formats" "INFO" "White"
    Write-Log "" "" "White"
    Write-Log "    [5] Open INPUT folder" "INFO" "DarkCyan"
    Write-Log "    [6] Open OUTPUT folder" "INFO" "DarkCyan"
    Write-Log "" "" "White"
    Write-Log "    [0] Exit" "INFO" "DarkGray"
    Write-Log "" "" "White"
    Write-Log "  -----------------------------------------------------------------" "INFO" "DarkGray"
    Write-Log "" "" "White"
}

function Show-SubMenu {
    param([string]$Type)
    Write-Log "" "" "White"
    Write-Log "  What do you want to do with $Type ?" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    Write-Log "    [C] CONVERT  - Change format" "INFO" "White"
    Write-Log "    [O] OPTIMIZE - Compress/reduce size" "INFO" "White"
    Write-Log "    [B] BACK     - Main menu" "INFO" "DarkGray"
    Write-Log "" "" "White"
}

function Show-FileCount {
    $imgCount = (Get-ChildItem -Path "$inputBase\images" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $audCount = (Get-ChildItem -Path "$inputBase\audio" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $vidCount = (Get-ChildItem -Path "$inputBase\video" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $docCount = (Get-ChildItem -Path "$inputBase\documents" -File -ErrorAction SilentlyContinue | Measure-Object).Count

    Write-Log "  Files in INPUT:" "INFO" "Cyan"
    Write-Log "     Images: $imgCount | Audio: $audCount | Video: $vidCount | Docs: $docCount" "INFO" "Gray"
    Write-Log "" "" "White"
}

# Main loop
do {
    Show-Header
    Show-FileCount
    Show-MainMenu

    $option = Read-Host "  Select an option"
    Write-Log "User selected option: $option" "DEBUG" "Black" # Hidden/Debug log

    switch ($option) {
        "1" {
            # IMAGES
            Show-Header
            Show-SubMenu "IMAGES"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Log "  IMAGE CONVERSION" "INFO" "Magenta"
                    Show-ImageFormats
                    $format = Read-Host "  Choose output format"
                    if ($format -ne "") {
                        Convert-Images -InputFolder "$inputBase\images" -OutputFolder "$outputBase\images" -OutputFormat $format
                    }
                    Pause-Script
                }
                "O" {
                    Show-Header
                    Write-Log "  IMAGE COMPRESSION" "INFO" "Magenta"
                    Show-ImageCompressionLevels
                    $level = Read-Host "  Choose compression level (1-4)"
                    
                    Write-Log "" "" "Cyan"
                    Write-Log "  Output format:" "INFO" "Cyan"
                    Write-Log "    [1] WEBP (best compression)" "INFO" "White"
                    Write-Log "    [2] JPG (most compatible)" "INFO" "White"
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
            if (-not (Test-Dependency "ffmpeg" "FFmpeg")) { Pause-Script; continue }
            
            Show-Header
            Show-SubMenu "AUDIO"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Log "  AUDIO CONVERSION" "INFO" "Magenta"
                    Show-AudioFormats
                    $format = Read-Host "  Choose output format"
                    if ($format -ne "") {
                        Convert-Audio -InputFolder "$inputBase\audio" -OutputFolder "$outputBase\audio" -OutputFormat $format
                    }
                    Pause-Script
                }
                "O" {
                    Show-Header
                    Write-Log "  AUDIO COMPRESSION" "INFO" "Magenta"
                    Show-AudioCompressionLevels
                    $level = Read-Host "  Choose compression level (1-4)"
                    if ($level -ne "") {
                        Compress-Audio -InputFolder "$inputBase\audio" -OutputFolder "$outputBase\audio" -Level $level
                    }
                    Pause-Script
                }
            }
        }
        "3" {
            # VIDEO
            if (-not (Test-Dependency "ffmpeg" "FFmpeg")) { Pause-Script; continue }
            
            Show-Header
            Show-SubMenu "VIDEO"
            $sub = Read-Host "  Option"
            
            switch ($sub.ToUpper()) {
                "C" {
                    Show-Header
                    Write-Log "  VIDEO CONVERSION" "INFO" "Magenta"

                    if (-not (Test-DiskSpace -Path $outputBase -RequiredMB 2048)) {
                        if (-not (Confirm-Action "Continue anyway?")) { Pause-Script; break }
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
                    Write-Log "  VIDEO COMPRESSION" "INFO" "Magenta"

                    if (-not (Test-DiskSpace -Path $outputBase -RequiredMB 2048)) {
                        if (-not (Confirm-Action "Continue anyway?")) { Pause-Script; break }
                    }

                    Show-VideoCompressionLevels
                    $level = Read-Host "  Choose compression level (1-4)"

                    Write-Log "" "" "White"
                    do {
                        $resize = Read-Host "  Downscale to 720p? (Y/N)"
                        $resizeUpper = $resize.ToUpper()
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
            if (-not (Test-Dependency "pandoc" "Pandoc")) { Pause-Script; continue }

            Show-Header
            Write-Log "  DOCUMENT CONVERSION" "INFO" "Magenta"
            Show-DocumentFormats
            $format = Read-Host "  Choose output format"
            if ($format -ne "") {
                Convert-Documents -InputFolder "$inputBase\documents" -OutputFolder "$outputBase\documents" -OutputFormat $format
            }
            Pause-Script
        }
        "5" { Start-Process explorer.exe $inputBase }
        "6" { Start-Process explorer.exe $outputBase }
        "0" {
            Write-Log "" "" "Cyan"
            Write-Log "  Goodbye!" "INFO" "Cyan"
            Write-Log "" "" "Cyan"
            exit
        }
        default {
            Write-Log "  [X] Invalid option" "WARN" "Red"
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
