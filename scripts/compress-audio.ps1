# ============================================
# AUDIO COMPRESSOR
# Uses FFmpeg for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressAudioFormats = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma", ".aiff", ".opus")

function Show-AudioCompressionLevels {
    Write-Host ""
    Write-Host "  Compression levels (bitrate):" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host "    [1] MAXIMUM   - 320 kbps (HiFi)" -ForegroundColor White
    Write-Host "    [2] HIGH      - 192 kbps (general use)" -ForegroundColor White
    Write-Host "    [3] MEDIUM    - 128 kbps (streaming)" -ForegroundColor White
    Write-Host "    [4] LOW       - 64 kbps (voice/podcasts)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Output format: MP3" -ForegroundColor DarkGray
    Write-Host ""
}

function Compress-Audio {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$Level
    )

    $bitrateMap = @{
        "1" = "320k"
        "2" = "192k"
        "3" = "128k"
        "4" = "64k"
    }

    if (-not $bitrateMap.ContainsKey($Level)) {
        Write-Host "[X] Invalid level" -ForegroundColor Red
        return 0
    }

    $bitrate = $bitrateMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressAudioFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Host "No audio files to compress in INPUT/audio/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Compressing $($files.Count) audio file(s) to $bitrate..." -ForegroundColor Cyan
    Write-Host ""

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed.mp3"
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($file.Name)" -ForegroundColor Gray -NoNewline

        try {
            $params = @("-i", $file.FullName, "-y", "-codec:a", "libmp3lame", "-b:a", $bitrate, $outputPath)
            
            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                $newSize = (Get-Item $outputPath).Length
                $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
                $totalSaved += ($originalSize - $newSize)
                
                if ($savings -gt 0) {
                    Write-Host " -> $outputName [-$savings%]" -ForegroundColor Green
                }
                else {
                    Write-Host " -> $outputName [no improvement]" -ForegroundColor Yellow
                }
                $processed++
            }
            else {
                Write-Host " [ERROR]" -ForegroundColor Red
            }
        }
        catch {
            Write-Host " [ERROR] $_" -ForegroundColor Red
        }
    }

    if ($totalSaved -gt 0) {
        $savedMB = [math]::Round($totalSaved / 1MB, 2)
        Write-Host ""
        Write-Host "  TOTAL SAVED: $savedMB MB" -ForegroundColor Green
    }

    return $processed
}
