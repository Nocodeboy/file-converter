# ============================================
# IMAGE COMPRESSOR
# Uses ImageMagick for optimization
# Author: German Huertas | License: MIT
# ============================================

$compressImageFormats = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp")

function Show-ImageCompressionLevels {
    Write-Log "" "" "Cyan"
    Write-Log "  Compression levels:" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    Write-Log "    [1] MAXIMUM   - 95% quality (professional photography)" "INFO" "White"
    Write-Log "    [2] HIGH      - 85% quality (general use)" "INFO" "White"
    Write-Log "    [3] MEDIUM    - 70% quality (web/email)" "INFO" "White"
    Write-Log "    [4] LOW       - 50% quality (thumbnails)" "INFO" "White"
    Write-Log "" "" "White"
    Write-Log "  Output format: WEBP (best compression) or JPG" "INFO" "DarkGray"
    Write-Log "" "" "White"
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
        Write-Log "[X] Invalid level" "ERROR" "Red"
        return 0
    }

    $quality = $qualityMap[$Level]
    $files = Get-ChildItem -Path $InputFolder -File | Where-Object { $compressImageFormats -contains $_.Extension.ToLower() }

    if ($files.Count -eq 0) {
        Write-Log "No images to compress in INPUT/images/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Compressing $($files.Count) image(s) at $quality% quality..." "INFO" "Cyan"
    Write-Log "" "" "Cyan"

    $processed = 0
    $totalSaved = 0

    foreach ($file in $files) {
        $originalSize = $file.Length
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + "_compressed." + $OutputFormat
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Log "  $($file.Name)" "INFO" "Gray" $true

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
