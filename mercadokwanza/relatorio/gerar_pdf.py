#!/usr/bin/env python3
"""Converte RELATORIO_Lab02.md -> Lab02_Grupo1.pdf usando pandoc + xhtml2pdf.

Não precisa de LaTeX nem de libs de sistema (Pango). Regista a fonte DejaVu
para acentos e símbolos saírem corretos.
"""
import subprocess
import glob
from xhtml2pdf import pisa

MD = "RELATORIO_Lab02.md"
PDF = "Lab02_Grupo1.pdf"

# Fonte DejaVu (vem com o matplotlib do Anaconda) para Unicode completo.
reg = glob.glob("/home/nuno-mendes/anaconda3/**/DejaVuSans.ttf", recursive=True)[0]
bold = glob.glob("/home/nuno-mendes/anaconda3/**/DejaVuSans-Bold.ttf", recursive=True)[0]

# 1) Markdown -> fragmento HTML (via pandoc).
body = subprocess.check_output(
    ["pandoc", MD, "-f", "gfm", "-t", "html"], text=True
)

# 2) Envolver com CSS para A4.
html = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: "DejaVu"; src: url("{reg}"); }}
@font-face {{ font-family: "DejaVu"; font-weight: bold; src: url("{bold}"); }}
@page {{ size: a4; margin: 2cm; }}
body {{ font-family: "DejaVu"; font-size: 10pt; line-height: 1.4; color: #1a1a1a; }}
h1 {{ font-size: 18pt; }} h2 {{ font-size: 14pt; border-bottom: 1px solid #ccc; }}
h3 {{ font-size: 11pt; }}
table {{ border-collapse: collapse; width: 100%; margin: 6px 0; }}
th, td {{ border: 1px solid #999; padding: 3px 5px; font-size: 8.5pt; }}
th {{ background: #ececec; }}
code {{ font-family: "DejaVu"; background: #f4f4f4; font-size: 9pt; }}
pre {{ background: #f4f4f4; padding: 6px; font-size: 8pt; }}
blockquote {{ color: #555; border-left: 3px solid #ccc; padding-left: 8px; }}
</style></head><body>{body}</body></html>"""

# 3) HTML -> PDF.
with open(PDF, "wb") as f:
    status = pisa.CreatePDF(html, dest=f, encoding="utf-8")

print("ERRO ao gerar PDF" if status.err else f"PDF gerado: {PDF}")
