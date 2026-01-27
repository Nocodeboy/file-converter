# ============================================
# AUDIO COMPRESSOR
# Uses FFmpeg for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressAudioFormats = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma", ".aiff", ".opus")

$compressOutputFormats = @{
    "1" = @{ ext = "mp3"; name = "MP3"; codec = "libmp3lame"; bitrateFlag = "-b:a" }
    "2" = @{ ext = "aac"; name = "AAC"; codec = "aac"; bitrateFlag = "-b:a" }
    "3" = @{ ext = "ogg"; name = "OGG"; codec = "libvorbis"; bitrateFlag = "-b:a" }
    "4" = @{ ext = "flac"; name = "FLAC (lossless)"; codec = "flac"; bitrateFlag = $null }
}

function Show-AudioOutputFormats {
    Write-Host ""
    Write-Host "  Available output formats:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    foreach ($key in ($compressOutputFormats.Keys | Sort-Object { [int]$_ })) {
        Write-Host "    [$key] $($compressOutputFormats[$key].name)" -ForegroundColor White
    }
    Write-Host ""
}

function Show-AudioCompressionLevels {
    param([string]$Format = "mp3")

    Write-Host ""
    Write-Host "  Compression levels (bitrate):" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host "    [1] MAXIMUM   - 320 kbps (HiFi)" -ForegroundColor White
    Write-Host "    [2] HIGH      - 192 kbps (general use)" -ForegroundColor White
    Write-Host "    [3] MEDIUM    - 128 kbps (streaming)" -ForegroundColor White
    Write-Host "    [4] LOW       - 64 kbps (voice/podcasts)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Output format: $($Format.ToUpper())" -ForegroundColor DarkGray
    Write-Host ""
}

function Compress-Audio {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$Level,
        [string]$OutputFormat = "1"
    )

    $bitrateMap = @{
        "1" = "320k"
        "2" = "192k"
        "3" = "128k"
        "4" = "64k"
    }

    if (-not $bitrateMap.ContainsKey($Level)) {
        Write-Host "[X] Invalid compression level. Choose 1-4." -ForegroundColor Red
        return 0
    }

    if (-not $compressOutputFormats.ContainsKey($OutputFormat)) {
        Write-Host "[X] Invalid output format. Choose 1-4." -ForegroundColor Red
        return 0
    }

    $bitrate = $bitrateMap[$Level]
    $formato = $compressOutputFormats[$OutputFormat]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressAudioFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Host "No audio files to compress in INPUT/audio/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    if ($formato.ext -eq "flac") {
        Write-Host "Converting $($files.Count) audio file(s) to FLAC (lossless)..." -ForegroundColor Cyan
    } else {
        Write-Host "Compressing $($files.Count) audio file(s) to $($formato.name) at $bitrate..." -ForegroundColor Cyan
    }
    Write-Host ""

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($file.Name)" -ForegroundColor Gray -NoNewline

        try {
            # Build params based on format (FLAC doesn't use bitrate)
            if ($null -eq $formato.bitrateFlag) {
                $params = @("-i", $file.FullName, "-y", "-codec:a", $formato.codec, $outputPath)
            } else {
                $params = @("-i", $file.FullName, "-y", "-codec:a", $formato.codec, $formato.bitrateFlag, $bitrate, $outputPath)
            }

            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                $newSize = (Get-Item $outputPath).Length
                $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
                $totalSaved += ($originalSize - $newSize)

                if ($savings -gt 0) {
                    Write-Host " -> $outputName [-$savings%]" -ForegroundColor Green
                }
                else {
                    Write-Host " -> $outputName [size increased or same]" -ForegroundColor Yellow
                }
                $processed++
            }
            else {
                Write-Host " [ERROR: FFmpeg failed - check if file is corrupted]" -ForegroundColor Red
            }
        }
        catch {
            Write-Host " [ERROR: $($_.Exception.Message)]" -ForegroundColor Red
        }
    }

    if ($totalSaved -gt 0) {
        $savedMB = [math]::Round($totalSaved / 1MB, 2)
        Write-Host ""
        Write-Host "  TOTAL SAVED: $savedMB MB" -ForegroundColor Green
    }
    elseif ($totalSaved -lt 0) {
        $increasedMB = [math]::Round((-$totalSaved) / 1MB, 2)
        Write-Host ""
        Write-Host "  NOTE: Total size increased by $increasedMB MB (lossless formats are larger)" -ForegroundColor Yellow
    }

    return $processed
}
