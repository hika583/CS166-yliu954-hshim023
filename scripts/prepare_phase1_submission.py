"""Build the Phase 1 PDFs and submission ZIP from the project files."""
from __future__ import annotations

import argparse
import hashlib
import html
import re
import shutil
import zipfile
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Preformatted, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
PDF_DIR = ROOT / 'output/pdf'
PACKAGE = ROOT / 'output/CS166_Phase1'
PDF_SOURCES = [
    ('docs/requirements.md', '01_Requirements.pdf'),
    ('docs/relational-schema.md', '03_Relational_Schema.pdf'),
    ('docs/testing.md', '06_Testing_Notes.pdf'),
]
PDF_NAMES = ['01_Requirements.pdf', '02_ER_Diagram.pdf',
             '03_Relational_Schema.pdf', '06_Testing_Notes.pdf']
LINKS = {'requirements.md': '01_Requirements.pdf',
         'test-results.txt': 'support/test-results.txt'}

styles = getSampleStyleSheet()
styles.add(ParagraphStyle('DocTitle', fontName='Helvetica-Bold', fontSize=16,
                          leading=20, spaceAfter=14))
styles.add(ParagraphStyle('SectionTitle', fontName='Helvetica-Bold', fontSize=11,
                          leading=14, spaceBefore=11, spaceAfter=6, keepWithNext=True))
styles.add(ParagraphStyle('Text', fontName='Helvetica', fontSize=9.5,
                          leading=13, spaceAfter=7))
styles.add(ParagraphStyle('ListText', parent=styles['Text'], leftIndent=12,
                          firstLineIndent=-8, spaceAfter=4))
styles.add(ParagraphStyle('Cell', fontName='Helvetica', fontSize=8.5,
                          leading=11, spaceAfter=0, splitLongWords=True))
styles.add(ParagraphStyle('CellHead', parent=styles['Cell'], fontName='Helvetica-Bold'))
styles.add(ParagraphStyle('CodeText', fontName='Courier', fontSize=7.7,
                          leading=10.8, spaceAfter=8))


def clean(text: str) -> str:
    return text.translate(str.maketrans({'\u2013': '-', '\u2014': '-',
                                         '\u2011': '-', '\u00a0': ' '}))


def inline(text: str) -> str:
    text = html.escape(clean(text))
    text = re.sub(r'`([^`]+)`', r'<font name="Courier">\1</font>', text)
    def link(match):
        label, target = match.groups()
        if target == 'requirements.md':
            label = 'Requirements document'
        target = LINKS.get(target, target)
        return f'<link href="{target}" color="#222222"><u>{label}</u></link>'
    return re.sub(r'\[([^]]+)\]\(([^)]+)\)', link, text)


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont('Helvetica', 8)
    canvas.drawString(42, 23, 'CS166 Project - Grade Database')
    canvas.drawRightString(570, 23, str(doc.page))
    canvas.restoreState()


def build_pdf(source: str, name: str):
    lines = (ROOT / source).read_text().splitlines()
    story = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('```'):
            block = []
            i += 1
            while i < len(lines) and not lines[i].startswith('```'):
                block.append(clean(lines[i]).replace('sql/load.sql', 'load.sql')
                             .replace('sql/test_constraints.sql', 'support/test_constraints.sql')
                             .replace('sql/queries.sql', 'support/queries.sql'))
                i += 1
            story.append(Preformatted('\n'.join(block), styles['CodeText']))
            i += 1
            continue
        if line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                cells = [cell.strip() for cell in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', cell) for cell in cells):
                    rows.append(cells)
                i += 1
            count = len(rows[0])
            if count == 3:
                widths = [198, 89, 241]
            elif rows[0][0] in {'Relationship', 'Relation'}:
                widths = [128, 400]
            elif rows[0][0] == 'Query':
                widths = [304, 224]
            else:
                widths = [121, 407]
            cells = [[Paragraph(inline(cell), styles['CellHead' if r == 0 else 'Cell'])
                      for cell in row] for r, row in enumerate(rows)]
            table = Table(cells, colWidths=widths, repeatRows=1, hAlign='LEFT')
            table.setStyle(TableStyle([
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#eeeeee')),
                ('LINEBELOW', (0, 0), (-1, 0), 0.5, colors.grey),
                ('LINEBELOW', (0, 1), (-1, -1), 0.25, colors.HexColor('#dddddd')),
                ('LEFTPADDING', (0, 0), (-1, -1), 5),
                ('RIGHTPADDING', (0, 0), (-1, -1), 5),
                ('TOPPADDING', (0, 0), (-1, -1), 4),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ]))
            story += [table, Spacer(1, 8)]
            continue
        if line.startswith('# '):
            story.append(Paragraph(inline(line[2:]), styles['DocTitle']))
            i += 1
            continue
        if line.startswith('## '):
            story.append(Paragraph(inline(line[3:]), styles['SectionTitle']))
            i += 1
            continue
        if re.match(r'(- |\d+\. )', line):
            item = line
            i += 1
            while i < len(lines) and lines[i].startswith('  ') and lines[i].strip():
                item += ' ' + lines[i].strip()
                i += 1
            story.append(Paragraph(inline(item), styles['ListText']))
            continue
        paragraph = line
        i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r'(#|\||```|- |\d+\. )', lines[i].strip()):
            paragraph += ' ' + lines[i].strip()
            i += 1
        story.append(Paragraph(inline(paragraph), styles['Text']))
    PDF_DIR.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(str(PDF_DIR/name), pagesize=(612, 792),
                            leftMargin=42, rightMargin=42, topMargin=38,
                            bottomMargin=38, title=lines[0].lstrip('# '),
                            author='', creator='ReportLab')
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f'Created {name}')


def package():
    PACKAGE.mkdir(parents=True, exist_ok=True)
    (PACKAGE/'support').mkdir(exist_ok=True)
    mapping = {name: PDF_DIR/name for name in PDF_NAMES}
    mapping.update({name: ROOT/'sql'/name for name in
                    ['create_tables.sql', 'sample_data.sql', 'load.sql']})
    mapping.update({f'support/{name}': ROOT/'sql'/name for name in
                    ['test_constraints.sql', 'queries.sql']})
    mapping['support/test-results.txt'] = ROOT/'docs/test-results.txt'
    for target, source in mapping.items():
        if not source.is_file():
            raise FileNotFoundError(source)
        shutil.copyfile(source, PACKAGE/target)
        assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256((PACKAGE/target).read_bytes()).digest()
    readme = '''# CS166 Phase 1 - Grade Database

## Deliverables

1. Requirements: 01_Requirements.pdf
2. ER diagram: 02_ER_Diagram.pdf
3. Relational schema: 03_Relational_Schema.pdf
4. Database creation: create_tables.sql
5. Sample data: sample_data.sql
6. Testing notes: 06_Testing_Notes.pdf

## Run

Use a running PostgreSQL server. From this folder:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/queries.sql
```

Use an empty database, or choose a different database name. load.sql runs the
creation and sample-data scripts in order. The tests roll back their changes.

Tested on PostgreSQL 17.11. Recorded output is in support/test-results.txt.
'''
    (PACKAGE/'README.md').write_text(readme)
    archive = ROOT/'output/CS166_Phase1.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name in [*mapping, 'README.md']:
            z.write(PACKAGE/name, arcname='CS166_Phase1/'+name)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert len(z.namelist()) == len(mapping)+1
    print(f'Created {archive}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pdf-only', action='store_true')
    parser.add_argument('--package-only', action='store_true')
    args = parser.parse_args()
    if not args.package_only:
        for source, name in PDF_SOURCES:
            build_pdf(source, name)
    if not args.pdf_only:
        package()
