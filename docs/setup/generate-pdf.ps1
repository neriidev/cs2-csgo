# Script para gerar PDF do guia de setup (se tiver pandoc instalado)
# Uso: .\generate-pdf.ps1   ou   pwsh -File generate-pdf.ps1

$ErrorActionPreference = "Stop"
$SetupDir = $PSScriptRoot
$Readme = Join-Path $SetupDir "README.md"
$PdfPath = Join-Path $SetupDir "setup-guia.pdf"

if (-not (Test-Path $Readme)) {
    Write-Error "README.md nao encontrado em: $SetupDir"
}

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) {
    Write-Host "Pandoc nao esta instalado. Para gerar o PDF:"
    Write-Host "  1. Abra README.md no browser ou VS Code e use Imprimir -> Guardar como PDF"
    Write-Host "  2. Ou instale pandoc: https://pandoc.org/installing.html"
    Write-Host "  3. Veja COMO-GERAR-PDF.md para mais opcoes."
    exit 1
}

Set-Location $SetupDir
try {
    & pandoc README.md -o setup-guia.pdf -V geometry:margin=2cm 2>&1
    if (Test-Path $PdfPath) {
        Write-Host "PDF gerado: $PdfPath"
    } else {
        Write-Host "Pandoc pode precisar de um motor PDF (ex.: texlive). Use a Opcao 1 em COMO-GERAR-PDF.md"
    }
} catch {
    Write-Host "Erro ao gerar PDF: $_"
    Write-Host "Use a Opcao 1 em COMO-GERAR-PDF.md (Imprimir -> Guardar como PDF)."
    exit 1
}
