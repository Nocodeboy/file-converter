# ============================================
# VIDEO COMPRESSOR
# Uses FFmpeg for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressVideoFormats = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpeg", ".mpg")

function Show-VideoCompressionLevels {
    Write-Host ""
    Write-Host "  Compression levels:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host "    [1] MAXIMUM   - CRF 18 (archive/editing)" -ForegroundColor White
    Write-Host "    [2] HIGH      - CRF 23 (general use)" -ForegroundColor White
    Write-Host "    [3] MEDIUM    - CRF 28 (share online)" -ForegroundColor White
    Write-Host "    [4] LOW       - CRF 35 (previews, max savings)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Additional options:" -ForegroundColor DarkGray
    Write-Host "    [R] Downscale resolution to 720p" -ForegroundColor DarkCyan
    Write-Host ""
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
        Write-Host "[X] Invalid level" -ForegroundColor Red
        return 0
    }

    $crf = $crfMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressVideoFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Host "No videos to compress in INPUT/video/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Compressing $($files.Count) video(s) with CRF $crf..." -ForegroundColor Cyan
    if ($Resize720) {
        Write-Host "   (Downscaling to 720p)" -ForegroundColor DarkGray
    }
    Write-Host "   (This may take several minutes per video)" -ForegroundColor DarkGray
    Write-Host ""

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed.mp4"
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($file.Name)" -ForegroundColor Gray -NoNewline

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
                    Write-Host " -> ${origMB}MB to ${newMB}MB [-$savings%]" -ForegroundColor Green
                }
                else {
                    Write-Host " -> [no improvement]" -ForegroundColor Yellow
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
