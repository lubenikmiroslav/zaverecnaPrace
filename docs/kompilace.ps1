# Skript pro kompilaci LaTeX dokumentace
# Vytvoří PDF a Word soubor

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "Kompilace závěrečné práce"
Write-Host "========================================"
Write-Host ""

# Zkontrolovat, jestli je pdflatex dostupný
$pdflatex = Get-Command pdflatex -ErrorAction SilentlyContinue
$bibtex = Get-Command bibtex -ErrorAction SilentlyContinue
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue

if (-not $pdflatex) {
    Write-Host "❌ pdflatex není nainstalován!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Možnosti kompilace:"
    Write-Host "1. Nainstalovat MiKTeX nebo TeX Live"
    Write-Host "2. Použít Overleaf (https://www.overleaf.com)"
    Write-Host "3. Použít online LaTeX kompilátor"
    Write-Host ""
    Write-Host "Pro použití Overleaf:"
    Write-Host "- Nahrajte všechny soubory z adresáře 'docs' do Overleaf projektu"
    Write-Host "- Nastavte hlavní soubor na 'main.tex'"
    Write-Host "- Klikněte na 'Recompile'"
    Write-Host ""
    exit 1
}

Write-Host "✅ pdflatex je dostupný" -ForegroundColor Green

# Kompilace LaTeX
Write-Host ""
Write-Host "Kompilace LaTeX dokumentu..." -ForegroundColor Yellow

# První kompilace
Write-Host "1. První kompilace..."
& pdflatex -interaction=nonstopmode main.tex | Out-Null

if ($bibtex) {
    Write-Host "2. Kompilace bibliografie..."
    & bibtex main | Out-Null
}

# Druhá kompilace
Write-Host "3. Druhá kompilace..."
& pdflatex -interaction=nonstopmode main.tex | Out-Null

# Třetí kompilace (pro správné odkazy)
Write-Host "4. Třetí kompilace..."
& pdflatex -interaction=nonstopmode main.tex | Out-Null

# Přejmenování PDF
if (Test-Path "main.pdf") {
    Copy-Item "main.pdf" "lubenik-zaverecna-prace-verze3.pdf" -Force
    Write-Host ""
    Write-Host "✅ PDF vytvořen: lubenik-zaverecna-prace-verze3.pdf" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Chyba při vytváření PDF" -ForegroundColor Red
}

# Převod na Word pomocí pandoc
if ($pandoc) {
    Write-Host ""
    Write-Host "Převod na Word pomocí pandoc..." -ForegroundColor Yellow
    & pandoc main.tex -o "lubenik-zaverecna-prace.docx" --from latex --to docx
    if (Test-Path "lubenik-zaverecna-prace.docx") {
        Write-Host "✅ Word vytvořen: lubenik-zaverecna-prace.docx" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "⚠️  pandoc není nainstalován - Word soubor nebude vytvořen" -ForegroundColor Yellow
    Write-Host "   Pro vytvoření Word souboru nainstalujte pandoc:"
    Write-Host "   https://pandoc.org/installing.html"
}

Write-Host ""
Write-Host "========================================"
Write-Host "Hotovo!"
Write-Host "========================================"

