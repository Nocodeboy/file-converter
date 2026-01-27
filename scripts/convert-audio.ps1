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
    Write-Log "" "" "Cyan"
    Write-Log "  Available output formats:" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    foreach ($key in ($audioFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Log "    [$key] $($audioFormatosSalida[$key].name)" "INFO" "White"
    }
    Write-Log "" "" "White"
}

function Convert-Audio {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $audioFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Log "[X] Invalid format" "ERROR" "Red"
        return 0
    }

    $formato = $audioFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $audioFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Log "No audio files to convert in INPUT/audio/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Converting $($archivos.Count) audio file(s) to $($formato.name)..." "INFO" "Cyan"
    Write-Log "" "" "Cyan"

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Log "  $($archivo.Name) -> $outputName" "INFO" "Gray" $true

        try {
            $params = @("-i", $archivo.FullName, "-y") + $formato.params + @($outputPath)
            
            & ffmpeg @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                Write-Log " [OK]" "INFO" "Green"
                $converted++
            }
            else {
                Write-Log " [ERROR]" "ERROR" "Red"
            }
        }
        catch {
            Write-Log " [ERROR] $_" "ERROR" "Red"
        }
    }

    return $converted
}
