# ============================================
# FILE CONVERTER - UTILITIES MODULE
# Shared functions and logging
# ============================================

# Ensure logs directory exists
$logDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "..\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "activity.log"

# --- LOGGING ---

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White",
        [bool]$NoNewline = $false
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8

    # Write to console
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

# --- UI & COMMON ---

function Show-Header {
    Clear-Host
    Write-Log "" "" "Cyan"
    Write-Log "  =================================================================" "INFO" "Cyan"
    Write-Log "                                                                   " "INFO" "Cyan"
    Write-Log "   ######  ### ##       ########                                   " "INFO" "Magenta"
    Write-Log "   ##       ## ##       ##                                         " "INFO" "Magenta"
    Write-Log "   #####    ## ##       #####                                      " "INFO" "Magenta"
    Write-Log "   ##       ## ##       ##                                         " "INFO" "Magenta"
    Write-Log "   ##      ### ######## ########                                   " "INFO" "Magenta"
    Write-Log "                                                                   " "INFO" "Cyan"
    Write-Log "    ######  #######  ##    ## ##     ## ######## ########          " "INFO" "Yellow"
    Write-Log "   ##       ##   ##  ###   ## ##     ## ##       ##   ##           " "INFO" "Yellow"
    Write-Log "   ##       ##   ##  ## ## ## ##     ## #####    ######            " "INFO" "Yellow"
    Write-Log "   ##       ##   ##  ##   ### ##   ##   ##       ##  ##            " "INFO" "Yellow"
    Write-Log "    ######  #######  ##    ##   ###     ######## ##   ##           " "INFO" "Yellow"
    Write-Log "                                                                   " "INFO" "Cyan"
    Write-Log "  =================================================================" "INFO" "Cyan"
    Write-Log "" "" "Cyan"
}

function Pause-Script {
    Write-Log "" "" "DarkGray"
    Write-Log "  Press any key to continue..." "INFO" "DarkGray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Confirm-Action {
    param([string]$Message)
    $confirm = Read-Host "  $Message (Y/N)"
    return ($confirm.ToUpper() -eq "Y")
}

# --- CHECKS ---

function Test-Dependency {
    param([string]$Command, [string]$Name)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Log "  [X] $Name not installed." "ERROR" "Red"
        return $false
    }
    return $true
}

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
            Write-Log "" "" "Yellow"
            Write-Log "  [WARNING] Low disk space: ${freeSpaceMB}MB available (need ${RequiredMB}MB)" "WARN" "Yellow"
            Write-Log "  Free up space before continuing to avoid conversion failures." "WARN" "Yellow"
            Write-Log "" "" "Yellow"
            return $false
        }
        return $true
    }
    catch {
        return $true
    }
}
