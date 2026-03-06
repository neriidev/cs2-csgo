# Como gerar o PDF do guia de configuração

O guia principal está em **README.md**. Pode obter um PDF das seguintes formas:

## Opção 1 – Browser (mais simples)

1. Abra **README.md** no GitHub (ou no VS Code com pré-visualização Markdown).
2. Use **Imprimir** (Ctrl+P).
3. Escolha **Guardar como PDF** ou **Microsoft Print to PDF** como destino.

## Opção 2 – Pandoc (linha de comando)

Se tiver **pandoc** e um motor PDF (ex.: TeX Live ou wkhtmltopdf):

```powershell
# Na pasta docs/setup
pandoc README.md -o setup-guia.pdf -V geometry:margin=2cm
```

Ou com xelatex (melhor para acentos):

```bash
pandoc README.md -o setup-guia.pdf --pdf-engine=xelatex -V mainfont="DejaVu Sans" -V geometry:margin=2cm
```

## Opção 3 – VS Code

1. Instale a extensão **Markdown PDF**.
2. Abra `README.md`.
3. Botão direito → **Markdown PDF: Export (pdf)**.
4. O PDF será criado na mesma pasta.

## Opção 4 – Node.js (md-to-pdf)

Na pasta `docs/setup/`:

```bash
npx md-to-pdf README.md
```

Será criado `README.pdf` (pode renomear para `setup-guia.pdf`).

## Opção 5 – Conversor online

1. Copie o conteúdo de **README.md**.
2. Use um site como [md2pdf](https://www.md2pdf.com/) ou [Dillinger](https://dillinger.io/) (export to PDF).
3. Guarde o ficheiro como `setup-guia.pdf` na pasta `docs/setup/`.

O PDF pode ser partilhado junto com o repositório.
