#!/bin/bash

LATEX_BODY="$1"
OUTDIR="textext_auto"
mkdir -p "$OUTDIR"

# 1. Create LaTeX file
echo "\documentclass{article}
\pagestyle{empty}
\begin{document}
$LATEX_BODY
\end{document}" > "$OUTDIR"/tmp.tex

# 2. Compile LaTeX
pdflatex -output-directory="$OUTDIR" "$OUTDIR"/tmp.tex > /dev/null

# 3. Convert to SVG
pdf2svg "$OUTDIR"/tmp.pdf "$OUTDIR"/tmp.svg

# 4. Insert into existing SVG (manually or via XML manipulation)
