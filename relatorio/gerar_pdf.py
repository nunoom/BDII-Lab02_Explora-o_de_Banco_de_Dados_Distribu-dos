#!/usr/bin/env python3
"""Converte RELATORIO_Lab02.md -> Lab02_Grupo1.pdf com um design moderno.

Motor: pandoc (Markdown->HTML) + xhtml2pdf (HTML->PDF). Não precisa de LaTeX
nem de libs de sistema. Capa estilizada, rodapé com nº de página, cor de marca.
"""
import glob
import subprocess
from xhtml2pdf import pisa

MD = "RELATORIO_Lab02.md"
PDF = "Lab02_Grupo1.pdf"

# ── Fontes DejaVu (vêm com o matplotlib do Anaconda) ────────────────
def font(name):
    return glob.glob(f"/home/nuno-mendes/anaconda3/**/{name}", recursive=True)[0]

F_REG = font("DejaVuSans.ttf")
F_BOLD = font("DejaVuSans-Bold.ttf")
F_ITAL = font("DejaVuSans-Oblique.ttf")
F_BDIT = font("DejaVuSans-BoldOblique.ttf")
F_MONO = font("DejaVuSansMono.ttf")

# ── Paleta ──────────────────────────────────────────────────────────
PRIMARY = "#0F766E"      # teal-700
PRIMARY_DK = "#134E4A"   # teal-900
ACCENT = "#F59E0B"       # amber-500
LIGHT = "#F0FDFA"        # teal-50
BORDER = "#CBD5E1"
TEXT = "#1F2937"
MUTED = "#64748B"

# ── 1) Corpo: só a partir da secção 2 (a capa é desenhada à parte) ──
md = open(MD, encoding="utf-8").read()
corte = md.find("## 2. PARTE 1")
body_md = md[corte:] if corte != -1 else md
body = subprocess.check_output(
    ["pandoc", "-f", "gfm", "-t", "html"], input=body_md, text=True
)

# ── 2) Capa desenhada em HTML ───────────────────────────────────────
cover = f"""
<div class="cover">
  <div class="accent"></div>
  <div class="band">
    <div class="inst">ISPTEC · Instituto Superior Politécnico de Tecnologias e Ciências</div>
    <div class="course">BASE DE DADOS II</div>
    <div class="title">Lab&nbsp;#02 — Bases de Dados Distribuídas</div>
    <div class="subtitle">Exploração de um Banco de Dados Distribuído · <b>MercadoKwanza</b></div>
  </div>

  <table class="meta">
    <tr><td class="k">Grupo</td><td class="v">Grupo 1</td></tr>
    <tr><td class="k">Cenário / Situação</td><td class="v">Cenário A — Defensor na primeira ronda (Situação A)</td></tr>
    <tr><td class="k">Turma</td><td class="v">M1</td></tr>
    <tr><td class="k">Data</td><td class="v">21 de Junho de 2026</td></tr>
  </table>

  <div class="members-label">ELEMENTOS DO GRUPO</div>
  <table class="members">
    <tr><td>Nuno Mendes</td><td>Khelv Costa</td></tr>
    <tr><td>Rafaela Mendes</td><td>Paula Alexandre</td></tr>
  </table>

  <div class="cover-foot">
    <b>Entrega:</b> <code>[BDD II] Lab02 — Grupo 1 — Situação A</code><br/>
    <b>Destinatário:</b> judson.paiva@isptec.co.ao
  </div>
</div>
<div style="page-break-after: always;"></div>
"""

# ── 3) CSS ──────────────────────────────────────────────────────────
css = f"""
@font-face {{ font-family:"DV"; src:url("{F_REG}"); }}
@font-face {{ font-family:"DV"; font-weight:bold; src:url("{F_BOLD}"); }}
@font-face {{ font-family:"DV"; font-style:italic; src:url("{F_ITAL}"); }}
@font-face {{ font-family:"DV"; font-weight:bold; font-style:italic; src:url("{F_BDIT}"); }}
@font-face {{ font-family:"DVMono"; src:url("{F_MONO}"); }}

@page {{
  size: a4;
  margin: 2.0cm 1.7cm 1.8cm 1.7cm;
  @frame footer {{
    -pdf-frame-content: footerContent;
    bottom: 0.9cm; margin-left: 1.7cm; margin-right: 1.7cm; height: 0.8cm;
  }}
}}

body {{ font-family:"DV"; font-size:10pt; line-height:1.45; color:{TEXT}; }}

/* ---------- CAPA ---------- */
.accent {{ background-color:{ACCENT}; height:6px; }}
.band {{ background-color:{PRIMARY}; padding:26px 24px 28px 24px; color:#ffffff; }}
.band .inst {{ font-size:9pt; color:#CCFBF1; }}
.band .course {{ font-size:11pt; color:#99F6E4; letter-spacing:3px; margin-top:14px; }}
.band .title {{ font-size:25pt; font-weight:bold; margin-top:6px; line-height:1.15; }}
.band .subtitle {{ font-size:11pt; color:#E0F2F1; margin-top:10px; }}

.meta {{ width:100%; margin-top:34px; border-collapse:collapse; }}
.meta td {{ padding:9px 10px; border-bottom:1px solid #E2E8F0; font-size:10.5pt; }}
.meta .k {{ color:{PRIMARY}; font-weight:bold; width:34%; }}
.meta .v {{ color:{TEXT}; }}

.members-label {{ margin-top:30px; color:{MUTED}; font-size:8.5pt; letter-spacing:2px; }}
.members {{ width:100%; margin-top:8px; border-collapse:collapse; }}
.members td {{ padding:8px 10px; font-size:11pt; background-color:{LIGHT};
               border:3px solid #ffffff; color:{PRIMARY_DK}; font-weight:bold; }}

.cover-foot {{ margin-top:40px; padding-top:12px; border-top:2px solid {PRIMARY};
               font-size:9pt; color:{MUTED}; }}

/* ---------- RODAPÉ ---------- */
#footerContent {{ font-size:7.5pt; color:{MUTED}; }}
.foot-table {{ width:100%; border-collapse:collapse; }}
.foot-table td {{ border-top:1px solid {BORDER}; padding-top:4px; }}

/* ---------- CORPO ---------- */
h2 {{ color:{PRIMARY_DK}; font-size:14pt; margin-top:20px; margin-bottom:8px;
      padding-bottom:4px; border-bottom:2px solid {PRIMARY}; }}
h3 {{ color:{PRIMARY}; font-size:11.5pt; margin-top:14px; margin-bottom:4px; }}
h4 {{ color:{TEXT}; font-size:10.5pt; margin-top:10px; margin-bottom:4px; }}
p {{ margin:5px 0; }}
strong, b {{ color:{PRIMARY_DK}; }}
a {{ color:{PRIMARY}; }}

table {{ border-collapse:collapse; width:100%; margin:8px 0; }}
th {{ background-color:{PRIMARY}; color:#ffffff; font-size:8.5pt; text-align:left;
      padding:5px 7px; }}
td {{ border:0.5px solid {BORDER}; font-size:8.8pt; padding:5px 7px;
      vertical-align:top; }}

blockquote {{ background-color:{LIGHT}; border-left:4px solid {ACCENT};
              margin:8px 0; padding:7px 12px; color:#334155; }}
blockquote p {{ margin:2px 0; }}

code {{ font-family:"DVMono"; background-color:#F1F5F9; color:{PRIMARY_DK};
        font-size:8.5pt; padding:1px 2px; }}
pre {{ background-color:#F1F5F9; color:#0F172A; padding:9px 11px; margin:7px 0;
       border-left:4px solid {PRIMARY}; font-family:"DVMono"; font-size:7.6pt;
       line-height:1.4; }}
pre code {{ background-color:#F1F5F9; color:#0F172A; font-size:7.6pt; }}

ul, ol {{ margin:5px 0 5px 0; }}
li {{ margin:2px 0; }}
hr {{ border:none; border-top:1px solid #E5E7EB; margin:14px 0; }}
"""

footer = (
    '<div id="footerContent"><table class="foot-table"><tr>'
    '<td align="left">MercadoKwanza · Lab #02 · Grupo 1 · Turma M1</td>'
    '<td align="right">Página <pdf:pagenumber> de <pdf:pagecount></td>'
    '</tr></table></div>'
)

html = (f'<!DOCTYPE html><html><head><meta charset="utf-8">'
        f'<style>{css}</style></head><body>{footer}{cover}{body}</body></html>')

with open(PDF, "wb") as f:
    status = pisa.CreatePDF(html, dest=f, encoding="utf-8")

print("ERRO ao gerar PDF" if status.err else f"PDF gerado: {PDF}")
