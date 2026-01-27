# ============================================
# AUDIO CONVERTER
# Uses FFmpeg for conversions
# Author: German Huertas | License: MIT
# ============================================

$audioFormatosEntrada = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma", ".aiff", ".opus")
$audioFormatosSalida = @{
    "1" = @{ ext = "mp3"; name = "MP3"; params = @("-codec:a", "libmp3lame", "-qscale:a", "2") }
    "2" = @{ ext = "wav"; name = "WAV"; params = @("-codec:a", "pcm_s16le") }
    "3" = @{ ext = "flac"; name = "FLAC"; params = @("-codec:a", "flac") }
    "4" = @{ ext = "aac"; name = "AAC"; params = @("-codec:a", "aac", "-b:a", "192k") }
    "5" = @{ ext = "ogg"; name = "OGG"; params = @("-codec:a", "libvorbis", "-qscale:a", "5") }
    "6" = @{ ext = "m4a"; name = "M4A"; params = @("-codec:a", "aac", "-b:a", "192k") }
}

function Show-AudioFormats {
    Write-Host ""
    Write-Host "  Available output formats:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    foreach ($key in ($audioFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Host "    [$key] $($audioFormatosSalida[$key].name)" -ForegroundColor White
    }
    Write-Host ""
}

function Convert-Audio {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $audioFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Host "[X] Invalid format" -ForegroundColor Red
        return 0
    }

    $formato = $audioFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $audioFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Host "No audio files to convert in INPUT/audio/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Converting $($archivos.Count) audio file(s) to $($formato.name)..." -ForegroundColor Cyan
    Write-Host ""

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($archivo.Name) -> $outputName" -ForegroundColor Gray -NoNewline

        try {
            $params = @("-i", $archivo.FullName, "-y") + $formato.params + @($outputPath)
            
            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                Write-Host " [OK]" -ForegroundColor Green
                $converted++
            }
            else {
                Write-Host " [ERROR]" -ForegroundColor Red
            }
        }
        catch {
            Write-Host " [ERROR] $_" -ForegroundColor Red
        }
    }

    return $converted
}
