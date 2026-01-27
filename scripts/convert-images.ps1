# ============================================
# IMAGE CONVERTER
# Uses ImageMagick for conversions
# Author: German Huertas | License: MIT
# ============================================

$imageFormatosEntrada = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif", ".webp", ".svg", ".ico", ".heic")
$imageFormatosSalida = @{
    "1" = @{ ext = "png"; name = "PNG" }
    "2" = @{ ext = "jpg"; name = "JPG" }
    "3" = @{ ext = "webp"; name = "WEBP" }
    "4" = @{ ext = "gif"; name = "GIF" }
    "5" = @{ ext = "ico"; name = "ICO" }
    "6" = @{ ext = "pdf"; name = "PDF" }
    "7" = @{ ext = "bmp"; name = "BMP" }
    "8" = @{ ext = "tiff"; name = "TIFF" }
}

function Show-ImageFormats {
    Write-Host ""
    Write-Host "  Available output formats:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    foreach ($key in ($imageFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Host "    [$key] $($imageFormatosSalida[$key].name)" -ForegroundColor White
    }
    Write-Host ""
}

function Convert-Images {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $imageFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Host "[X] Invalid format" -ForegroundColor Red
        return 0
    }

    $formato = $imageFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $imageFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Host "No images to convert in INPUT/images/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Converting $($archivos.Count) image(s) to $($formato.name)..." -ForegroundColor Cyan
    Write-Host ""

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        # Check if output file already exists
        if (Test-Path $outputPath) {
            Write-Host "  $($archivo.Name) -> $outputName" -ForegroundColor Gray -NoNewline
            Write-Host " [SKIPPED: file exists]" -ForegroundColor Yellow
            continue
        }

        Write-Host "  $($archivo.Name) -> $outputName" -ForegroundColor Gray -NoNewline

        try {
            $params = @($archivo.FullName, $outputPath)

            if ($formato.ext -eq "jpg") {
                $params = @($archivo.FullName, "-quality", "90", $outputPath)
            }
            elseif ($formato.ext -eq "webp") {
                $params = @($archivo.FullName, "-quality", "85", $outputPath)
            }
            elseif ($formato.ext -eq "ico") {
                $params = @($archivo.FullName, "-resize", "256x256", $outputPath)
            }

            $magickOutput = & magick @params 2>&1

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                Write-Host " [OK]" -ForegroundColor Green
                $converted++
            }
            else {
                $errorMsg = if ($magickOutput) { $magickOutput | Select-Object -First 1 } else { "ImageMagick conversion failed" }
                Write-Host " [ERROR: $errorMsg]" -ForegroundColor Red
            }
        }
        catch {
            Write-Host " [ERROR: $($_.Exception.Message)]" -ForegroundColor Red
        }
    }

    return $converted
}
