"""Build the combined Phase 1 report and package the submission files."""
from __future__ import annotations

import argparse
import re
import shutil
import zipfile
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT/'output/CS166_Phase1'
DOCX = ROOT/'docs/phase1-report.docx'
PDF_DIR = ROOT/'output/pdf'
SCREENSHOTS = {
    '[Screenshot: database load]': ('database-load.jpg', 'Database load and sample rows'),
    '[Screenshot: constraint checks]': ('constraint-checks.jpg', 'Constraint checks and rejected records'),
    '[Screenshot: query results]': ('query-results.jpg', 'Grade calculation and students without grades'),
}


def add_text(paragraph, text):
    for i, chunk in enumerate(re.split(r'`([^`]+)`', text)):
        run = paragraph.add_run(chunk)
        if i % 2:
            run.font.name = 'Courier New'
            run.font.size = Pt(9)


def build_docx():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = section.bottom_margin = Inches(0.7)
    section.left_margin = section.right_margin = Inches(0.8)
    for name in ['Normal', 'Title', 'Heading 1', 'Caption']:
        style = doc.styles[name]
        style.font.name = 'Times New Roman'
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.line_spacing = 1
        fonts = style.element.rPr.rFonts
        if fonts is not None:
            for key in list(fonts.attrib):
                if key.lower().endswith('theme'):
                    del fonts.attrib[key]
        for border in list(style.element.iter(qn('w:pBdr'))):
            border.getparent().remove(border)
    normal = doc.styles['Normal']
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    title = doc.styles['Title']
    title.font.size = Pt(15)
    title.font.bold = True
    title.paragraph_format.space_after = Pt(10)
    heading = doc.styles['Heading 1']
    heading.font.size = Pt(12)
    heading.font.bold = True
    heading.paragraph_format.space_before = Pt(8)
    heading.paragraph_format.space_after = Pt(7)
    heading.paragraph_format.keep_with_next = True
    caption = doc.styles['Caption']
    caption.font.size = Pt(10)
    caption.font.italic = False
    caption.paragraph_format.space_after = Pt(5)
    caption.paragraph_format.keep_with_next = True
    footer = section.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    field = OxmlElement('w:fldSimple')
    field.set(qn('w:instr'), 'PAGE')
    footer._p.append(field)
    doc.core_properties.author = ''
    doc.core_properties.last_modified_by = ''
    doc.core_properties.title = 'CS166 Project Phase 1'
    doc.core_properties.subject = 'Requirements relational schema and testing'
    lines = (ROOT/'docs/phase1-report.md').read_text().splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('# '):
            doc.add_paragraph(line[2:], 'Title')
            p = doc.add_paragraph('yliu954 and hshim023')
            p.paragraph_format.space_after = Pt(8)
            i += 1
            continue
        if line.startswith('## '):
            p = doc.add_paragraph(line[3:], 'Heading 1')
            if line.startswith('## 2 ') or line.startswith('## 3 '):
                p.paragraph_format.page_break_before = True
            i += 1
            continue
        if line in SCREENSHOTS:
            filename, label = SCREENSHOTS[line]
            image_path = ROOT/'docs/screenshots'/filename
            with Image.open(image_path) as image:
                w, h = image.size
            width = min(6.45, 7.3 * w / h)
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(9)
            p.add_run().add_picture(str(image_path), width=Inches(width))
            i += 1
            continue
        if line.startswith('```'):
            i += 1
            block = []
            while i < len(lines) and not lines[i].startswith('```'):
                block.append(lines[i])
                i += 1
            p = doc.add_paragraph()
            p.paragraph_format.line_spacing = 1
            p.paragraph_format.space_after = Pt(6)
            r = p.add_run('\n'.join(block))
            r.font.name = 'Courier New'
            r.font.size = Pt(8)
            i += 1
            continue
        if line.startswith('- '):
            text = line[2:]
            i += 1
            while i < len(lines) and lines[i].startswith('  ') and lines[i].strip():
                text += ' ' + lines[i].strip()
                i += 1
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.15)
            p.paragraph_format.first_line_indent = Inches(-0.15)
            p.paragraph_format.space_after = Pt(3)
            add_text(p, '- ' + text)
            continue
        text = line
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].startswith(('#', '- ', '```', '[Screenshot:')):
            text += ' ' + lines[i].strip()
            i += 1
        add_text(doc.add_paragraph(), text)
    doc.save(DOCX)
    print(DOCX)


def original_diagram():
    from reportlab.pdfgen import canvas
    source = ROOT/'docs/er-diagram.png'
    with Image.open(source) as image:
        w, h = image.size
    PDF_DIR.mkdir(parents=True, exist_ok=True)
    destination = PDF_DIR/'ER_Diagram.pdf'
    pdf = canvas.Canvas(str(destination), pagesize=(w, h))
    pdf.setTitle('CS166 ER Diagram')
    pdf.setAuthor('')
    pdf.setCreator('ReportLab')
    pdf.drawImage(str(source), 0, 0, width=w, height=h, mask='auto')
    pdf.showPage()
    pdf.save()
    print(destination)


def package():
    PACKAGE.mkdir(parents=True, exist_ok=True)
    (PACKAGE/'support/screenshots').mkdir(parents=True, exist_ok=True)
    # Remove the separate reports and replacement diagram from the old package.
    for name in ['01_Requirements.pdf', '02_ER_Diagram.pdf', '03_Relational_Schema.pdf', '06_Testing_Notes.pdf']:
        old = PACKAGE/name
        if old.exists():
            old.unlink()
    mapping = {
        'Phase1_Report.pdf': PDF_DIR/'Phase1_Report.pdf',
        'ER_Diagram.pdf': PDF_DIR/'ER_Diagram.pdf',
        'create_tables.sql': ROOT/'sql/create_tables.sql',
        'sample_data.sql': ROOT/'sql/sample_data.sql',
        'load.sql': ROOT/'sql/load.sql',
        'support/test_constraints.sql': ROOT/'sql/test_constraints.sql',
        'support/queries.sql': ROOT/'sql/queries.sql',
        'support/test-results.txt': ROOT/'docs/test-results.txt',
        'support/screenshot-output.txt': ROOT/'docs/screenshot-output.txt',
    }
    mapping.update({f'support/screenshots/{name}': ROOT/'docs/screenshots'/name
                    for name, _ in SCREENSHOTS.values()})
    for name, source in mapping.items():
        shutil.copyfile(source, PACKAGE/name)
        assert source.read_bytes() == (PACKAGE/name).read_bytes()
    (PACKAGE/'README.md').write_text('''# CS166 Phase 1

Phase1_Report.pdf combines the requirements, relational schema, and testing
notes, including screenshots. ER_Diagram.pdf is the original teammate diagram.
create_tables.sql creates the schema; sample_data.sql inserts the sample rows.

From this folder, with PostgreSQL running:

```sh
createdb cs166_project
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f load.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/test_constraints.sql
psql -X -v ON_ERROR_STOP=1 -d cs166_project -f support/queries.sql
```

Use an empty database. Tests roll back their changes. Logs and screenshots are
in support. The screenshots show actual psql output displayed in a local page.
''')
    archive = ROOT/'output/CS166_Phase1.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name in [*mapping, 'README.md']:
            z.write(PACKAGE/name, arcname='CS166_Phase1/'+name)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert len(z.namelist()) == len(mapping)+1
    print(archive)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['docx', 'diagram', 'package'])
    args = parser.parse_args()
    {'docx': build_docx, 'diagram': original_diagram, 'package': package}[args.action]()
