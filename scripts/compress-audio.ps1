# ============================================
# AUDIO COMPRESSOR
# Uses FFmpeg for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressAudioFormats = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma", ".aiff", ".opus")

function Show-AudioCompressionLevels {
    Write-Log "" "" "Cyan"
    Write-Log "  Compression levels (bitrate):" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    Write-Log "    [1] MAXIMUM   - 320 kbps (HiFi)" "INFO" "White"
    Write-Log "    [2] HIGH      - 192 kbps (general use)" "INFO" "White"
    Write-Log "    [3] MEDIUM    - 128 kbps (streaming)" "INFO" "White"
    Write-Log "    [4] LOW       - 64 kbps (voice/podcasts)" "INFO" "White"
    Write-Log "" "" "White"
    Write-Log "  Output format: MP3" "INFO" "DarkGray"
    Write-Log "" "" "White"
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
        Write-Log "[X] Invalid level" "ERROR" "Red"
        return 0
    }

    $bitrate = $bitrateMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressAudioFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Log "No audio files to compress in INPUT/audio/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Compressing $($files.Count) audio file(s) to $bitrate..." "INFO" "Cyan"
    Write-Log "" "" "Cyan"

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed.mp3"
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Log "  $($file.Name)" "INFO" "Gray" $true

        try {
            $params = @("-i", $file.FullName, "-y", "-codec:a", "libmp3lame", "-b:a", $bitrate, $outputPath)
            
            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                $newSize = (Get-Item $outputPath).Length
                $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
                $totalSaved += ($originalSize - $newSize)
                
                if ($savings -gt 0) {
                    Write-Log " -> $outputName [-$savings%]" "INFO" "Green"
                }
                else {
                    Write-Log " -> $outputName [no improvement]" "WARN" "Yellow"
                }
                $processed++
            }
            else {
                Write-Log " [ERROR]" "ERROR" "Red"
            }
        }
        catch {
            Write-Log " [ERROR] $_" "ERROR" "Red"
        }
    }

    if ($totalSaved -gt 0) {
        $savedMB = [math]::Round($totalSaved / 1MB, 2)
        Write-Log "" "" "Green"
        Write-Log "  TOTAL SAVED: $savedMB MB" "INFO" "Green"
    }

    return $processed
}
