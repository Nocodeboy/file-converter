# ============================================
# VIDEO CONVERTER
# Uses FFmpeg for conversions
# Author: German Huertas | License: MIT
# ============================================

$videoFormatosEntrada = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v", ".mpeg", ".mpg", ".3gp")
$videoFormatosSalida = @{
    "1" = @{ ext = "mp4"; name = "MP4"; params = @("-codec:v", "libx264", "-preset", "medium", "-crf", "23", "-codec:a", "aac", "-b:a", "128k") }
    "2" = @{ ext = "avi"; name = "AVI"; params = @("-codec:v", "mpeg4", "-qscale:v", "5", "-codec:a", "mp3", "-b:a", "128k") }
    "3" = @{ ext = "mkv"; name = "MKV"; params = @("-codec:v", "libx264", "-preset", "medium", "-crf", "23", "-codec:a", "aac", "-b:a", "128k") }
    "4" = @{ ext = "webm"; name = "WEBM"; params = @("-codec:v", "libvpx-vp9", "-crf", "30", "-b:v", "0", "-codec:a", "libopus", "-b:a", "128k") }
    "5" = @{ ext = "gif"; name = "GIF (animated)"; params = @("-vf", "fps=10,scale=480:-1:flags=lanczos", "-loop", "0") }
    "6" = @{ ext = "mp3"; name = "MP3 (audio only)"; params = @("-vn", "-codec:a", "libmp3lame", "-qscale:a", "2") }
    "7" = @{ ext = "mov"; name = "MOV"; params = @("-codec:v", "libx264", "-preset", "medium", "-crf", "23", "-codec:a", "aac", "-b:a", "128k") }
}

function Show-VideoFormats {
    Write-Log "" "" "Cyan"
    Write-Log "  Available output formats:" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    foreach ($key in ($videoFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Log "    [$key] $($videoFormatosSalida[$key].name)" "INFO" "White"
    }
    Write-Log "" "" "White"
}

function Convert-Video {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $videoFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Log "[X] Invalid format" "ERROR" "Red"
        return 0
    }

    $formato = $videoFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $videoFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Log "No video files to convert in INPUT/video/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Converting $($archivos.Count) video(s) to $($formato.name)..." "INFO" "Cyan"
    Write-Log "   (This may take several minutes per video)" "INFO" "DarkGray"
    Write-Log "" "" "Cyan"

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        
        if ($formato.ext -eq "mp3") {
            $outputPath = Join-Path (Split-Path $OutputFolder -Parent) "audio" $outputName
        }
        else {
            $outputPath = Join-Path $OutputFolder $outputName
        }

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
