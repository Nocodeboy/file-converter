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
    Write-Host ""
    Write-Host "  Available output formats:" -ForegroundColor Cyan
    Write-Host "  ---------------------------------" -ForegroundColor DarkGray
    foreach ($key in ($docFormatosSalida.Keys | Sort-Object { [int]$_ })) {
        Write-Host "    [$key] $($docFormatosSalida[$key].name)" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "  [!] PDF requires LaTeX installed (MiKTeX or TeX Live)" -ForegroundColor Yellow
    Write-Host ""
}

function Convert-Documents {
    param(
        [string]$InputFolder,
        [string]$OutputFolder,
        [string]$OutputFormat
    )

    if (-not $docFormatosSalida.ContainsKey($OutputFormat)) {
        Write-Host "[X] Invalid format" -ForegroundColor Red
        return 0
    }

    $formato = $docFormatosSalida[$OutputFormat]
    $archivos = Get-ChildItem -Path $InputFolder -File | Where-Object { $docFormatosEntrada -contains $_.Extension.ToLower() }

    if ($archivos.Count -eq 0) {
        Write-Host "No documents to convert in INPUT/documents/" -ForegroundColor Yellow
        return 0
    }

    Write-Host ""
    Write-Host "Converting $($archivos.Count) document(s) to $($formato.name)..." -ForegroundColor Cyan
    Write-Host ""

    $converted = 0
    foreach ($archivo in $archivos) {
        $outputName = [System.IO.Path]::GetFileNameWithoutExtension($archivo.Name) + "." + $formato.ext
        $outputPath = Join-Path $OutputFolder $outputName

        Write-Host "  $($archivo.Name) -> $outputName" -ForegroundColor Gray -NoNewline

        try {
            $params = @($archivo.FullName, "-o", $outputPath)
            
            if ($formato.ext -eq "pdf") {
                $params = @($archivo.FullName, "-o", $outputPath, "--pdf-engine=xelatex")
            }
            
            & pandoc @params 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                Write-Host " [OK]" -ForegroundColor Green
                $converted++
            }
            else {
                if ($formato.ext -eq "pdf") {
                    $params = @($archivo.FullName, "-o", $outputPath)
                    & pandoc @params 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
                        Write-Host " [OK]" -ForegroundColor Green
                        $converted++
                    }
                    else {
                        Write-Host " [ERROR] (LaTeX installed?)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host " [ERROR]" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host " [ERROR] $_" -ForegroundColor Red
        }
    }

    return $converted
}
