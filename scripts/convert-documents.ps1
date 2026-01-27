# ============================================
# DOCUMENT CONVERTER
# Uses Pandoc for conversions
# Author: German Huertas | License: MIT
# ============================================

$docFormatosEntrada = @(".md", ".markdown", ".txt", ".html", ".htm", ".docx", ".rst", ".org", ".tex", ".epub", ".odt")
$docFormatosSalida = @{
    "1" = @{ ext = "pdf"; name = "PDF"; format = "pdf" }
    "2" = @{ ext = "docx"; name = "Word (DOCX)"; format = "docx" }
    "3" = @{ ext = "html"; name = "HTML"; format = "html" }
    "4" = @{ ext = "txt"; name = "Plain Text (TXT)"; format = "plain" }
    "5" = @{ ext = "md"; name = "Markdown"; format = "markdown" }
    "6" = @{ ext = "epub"; name = "EPUB (eBook)"; format = "epub" }
    "7" = @{ ext = "odt"; name = "OpenDocument (ODT)"; format = "odt" }
}

function Show-DocumentFormats {
    Write-Log "" "" "Cyan"
    Write-Log "  Available output formats:" "INFO" "Cyan"
    Write-Log "  ---------------------------------" "INFO" "DarkGray"
    foreach ($key in ($docFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Log "    [$key] $($docFormatosSalida[$key].name)" "INFO" "White"
    }
    Write-Log "" "" "White"
    Write-Log "  [!] PDF requires LaTeX installed (MiKTeX or TeX Live)" "INFO" "Yellow"
    Write-Log "" "" "White"
}

function Convert-Documents {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $docFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Log "[X] Invalid format" "ERROR" "Red"
        return 0
    }

    $formato = $docFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $docFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Log "No documents to convert in INPUT/documents/" "WARN" "Yellow"
        return 0
    }

    Write-Log "" "" "Cyan"
    Write-Log "Converting $($archivos.Count) document(s) to $($formato.name)..." "INFO" "Cyan"
    Write-Log "" "" "Cyan"

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Log "  $($archivo.Name) -> $outputName" "INFO" "Gray" $true

        try {
            $params = @($archivo.FullName, "-o", $outputPath)
            
            if ($formato.ext -eq "pdf") {
                $params = @($archivo.FullName, "-o", $outputPath, "--pdf-engine=xelatex")
            }
            
            & pandoc @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                Write-Log " [OK]" "INFO" "Green"
                $converted++
            }
            else {
                if ($formato.ext -eq "pdf") {
                    $params = @($archivo.FullName, "-o", $outputPath)
                    & pandoc @params 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                        Write-Log " [OK]" "INFO" "Green"
                        $converted++
                    }
                    else {
                        Write-Log " [ERROR] (LaTeX installed?)" "ERROR" "Red"
                    }
                }
                else {
                    Write-Log " [ERROR]" "ERROR" "Red"
                }
            }
        }
        catch {
            Write-Log " [ERROR] $_" "ERROR" "Red"
        }
    }

    return $converted
}
