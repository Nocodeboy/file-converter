# ============================================
# VIDEO COMPRESSOR
# Uses FFmpeg for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressVideoFormats = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpeg", ".mpg")

function Show-VideoCompressionLevels {
    Write-Log "" "" "Cyan"
    Write-Log "  Compression levels:" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    Write-Log "    [1] MAXIMUM   - CRF 18 (archive/editing)" "INFO" "White"
    Write-Log "    [2] HIGH      - CRF 23 (general use)" "INFO" "White"
    Write-Log "    [3] MEDIUM    - CRF 28 (share online)" "INFO" "White"
    Write-Log "    [4] LOW       - CRF 35 (previews, max savings)" "INFO" "White"
    Write-Log "" "" "White"
    Write-Log "  Additional options:" "INFO" "DarkGray"
    Write-Log "    [R] Downscale resolution to 720p" "INFO" "DarkCyan"
    Write-Log "" "" "White"
}

function Compress-Video {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$Level,
        [bool]$Resize720 = $false
    )

    $crfMap = @{
        "1" = 18
        "2" = 23
        "3" = 28
        "4" = 35
    }

    if (-not $crfMap.ContainsKey($Level)) {
        Write-Log "[X] Invalid level" "ERROR" "Red"
        return 0
    }

    $crf = $crfMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressVideoFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Log "No videos to compress in INPUT/video/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Compressing $($files.Count) video(s) with CRF $crf..." "INFO" "Cyan"
    if ($Resize720) {
        Write-Log "   (Downscaling to 720p)" "INFO" "DarkGray"
    }
    Write-Log "   (This may take several minutes per video)" "INFO" "DarkGray"
    Write-Log "" "" "Cyan"

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed.mp4"
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Log "  $($file.Name)" "INFO" "Gray" $true

        try {
            $params = @("-i", $file.FullName, "-y", "-codec:v", "libx264", "-preset", "medium", "-crf", "$crf", "-codec:a", "aac", "-b:a", "128k")
            
            if ($Resize720) {
                $params += @("-vf", "scale=-2:720")
            }
            
            $params += @($outputPath)
            
            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                $newSize = (Get-Item $outputPath).Length
                $savings = [math]::Round((1 - ($newSize / $originalSize)) * 100, 1)
                $totalSaved += ($originalSize - $newSize)
                
                $origMB = [math]::Round($originalSize / 1MB, 1)
                $newMB = [math]::Round($newSize / 1MB, 1)
                
                if ($savings -gt 0) {
                    Write-Log " -> ${origMB}MB to ${newMB}MB [-$savings%]" "INFO" "Green"
                }
                else {
                    Write-Log " -> [no improvement]" "WARN" "Yellow"
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
