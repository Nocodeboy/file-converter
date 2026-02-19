<#
.SYNOPSIS
Build a standalone Windows executable launcher for File Converter CLI.

.DESCRIPTION
Uses ps2exe to package CONVERT.ps1 as FileConverter.exe.
If ps2exe is not installed, this script installs it for CurrentUser.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\scripts\build-exe.ps1
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".\FileConverter.exe"
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$inputScript = Join-Path $repoRoot 'CONVERT.ps1'
$outputExe = Resolve-Path -LiteralPath (Split-Path -Parent $OutputPath) -ErrorAction SilentlyContinue
if (-not $outputExe) {
    $parent = Split-Path -Parent $OutputPath
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = '.' }
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

if (-not (Test-Path $inputScript)) {
    throw "Cannot find CONVERT.ps1 in repo root: $inputScript"
}

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host 'Installing ps2exe module (CurrentUser)...' -ForegroundColor Yellow
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}

Import-Module ps2exe

Invoke-ps2exe `
    -inputFile $inputScript `
    -outputFile $OutputPath `
    -x64 `
    -title 'File Converter' `
    -product 'File Converter' `
    -version '2.1.0.0' `
    -noConsole:$false

Write-Host "Executable generated at: $OutputPath" -ForegroundColor Green
