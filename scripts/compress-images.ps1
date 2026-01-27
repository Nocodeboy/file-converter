# ============================================
# IMAGE COMPRESSOR
# Uses ImageMagick for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressImageFormats = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp")

function Show-ImageCompressionLevels {
    Write-Host ""
    Write-Host "  Compression levels:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    Write-Host "    [1] MAXIMUM   - 95% quality (professional photography)" -ForegroundColor White
    Write-Host "    [2] HIGH      - 85% quality (general use)" -ForegroundColor White
    Write-Host "    [3] MEDIUM    - 70% quality (web/email)" -ForegroundColor White
    Write-Host "    [4] LOW       - 50% quality (thumbnails)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Output format: WEBP (best compression) or JPG" -ForegroundColor DarkGray
    Write-Host ""
}

function Compress-Images {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$Level,
        [string]$OutputFormat = "webp"
    )

    $qualityMap = @{
        "1" = 95
        "2" = 85
        "3" = 70
        "4" = 50
    }

    if (-not $qualityMap.ContainsKey($Level)) {
        Write-Host "[X] Invalid level" -ForegroundColor Red
        return 0
    }

    $quality = $qualityMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressImageFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Host "No images to compress in INPUT/images/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Compressing $($files.Count) image(s) at $quality% quality..." -ForegroundColor Cyan
    Write-Host ""

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed." + $OutputFormat
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($file.Name)" -ForegroundColor Gray -NoNewline

        try {
            $params = @($file.FullName, "-quality", "$quality", "-strip", $outputPath)
            
            if ($OutputFormat -eq "webp") {
                $params = @($file.FullName, "-quality", "$quality", "-define", "webp:lossless=false", "-strip", $outputPath)
            }

            & magick @params 2>&1 | Out-Null

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
