"""Build the Phase 1 Chen ER diagram using ReportLab."""
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.utils import simpleSplit

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output/pdf/02_ER_Diagram.pdf'
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
PAGE_W, PAGE_H = 1600, 1100
c = canvas.Canvas(str(OUTPUT), pagesize=(PAGE_W, PAGE_H))
c.setTitle('CS166 Grade Database - ER Diagram')
c.setAuthor('')
c.setCreator('ReportLab')
c.setLineWidth(1.5)


def text(x, y, label, size=14, bold=False):
    c.setFont('Helvetica-Bold' if bold else 'Helvetica', size)
    c.drawCentredString(x, y, label)


def route(points):
    p = c.beginPath()
    p.moveTo(*points[0])
    for x, y in points[1:]:
        p.lineTo(x, y)
    c.drawPath(p)


def entity(x, y, label, w=170, h=60, weak=False):
    c.setFillColorRGB(1, 1, 1)
    c.rect(x-w/2, y-h/2, w, h, stroke=1, fill=1)
    if weak:
        c.rect(x-w/2+6, y-h/2+6, w-12, h-12, stroke=1, fill=0)
    c.setFillColorRGB(0, 0, 0)
    text(x, y-5, label, 17, True)


def diamond(x, y, label, w=160, h=68, identifying=False):
    p = c.beginPath()
    p.moveTo(x-w/2, y)
    p.lineTo(x, y+h/2)
    p.lineTo(x+w/2, y)
    p.lineTo(x, y-h/2)
    p.close()
    c.setFillColorRGB(1, 1, 1)
    c.drawPath(p, fill=1)
    if identifying:
        p = c.beginPath()
        p.moveTo(x-w/2+7, y)
        p.lineTo(x, y+h/2-6)
        p.lineTo(x+w/2-7, y)
        p.lineTo(x, y-h/2+6)
        p.close()
        c.drawPath(p)
    c.setFillColorRGB(0, 0, 0)
    text(x, y-4, label, 14)


def attr(x, y, label, w=140, key=False, partial=False):
    c.setFillColorRGB(1, 1, 1)
    c.ellipse(x-w/2, y-24, x+w/2, y+24, stroke=1, fill=1)
    c.setFillColorRGB(0, 0, 0)
    text(x, y-5, label, 14)
    if key or partial:
        width = c.stringWidth(label, 'Helvetica', 14)
        if partial:
            c.setDash(3, 2)
        c.line(x-width/2, y-8, x+width/2, y-8)
        c.setDash()


def card(x, y, value):
    # White backing keeps cardinalities readable beside their relationship line.
    c.setFont('Helvetica', 13)
    width = c.stringWidth(value, 'Helvetica', 13)
    c.setFillColorRGB(1, 1, 1)
    c.rect(x-width/2-3, y-3, width+6, 17, fill=1, stroke=0)
    c.setFillColorRGB(0, 0, 0)
    c.drawCentredString(x, y, value)


# Relationship edges (drawn before the shapes).
# Professor <-> Department: separate membership and management relationships.
route([(335,850),(470,900)])
route([(630,900),(760,850)])
route([(335,850),(470,800)])
route([(630,800),(760,850)])
# Professor <-> Section.
route([(250,820),(300,684)])
route([(380,650),(430,650),(555,500)])
# Department <-> Section.
route([(850,820),(850,714)])
route([(850,646),(700,535)])
# Department <-> Student.
route([(940,850),(1020,850)])
route([(1180,850),(1300,680)])
# Course <-> Section.
route([(250,230),(300,366)])
route([(300,434),(555,500)])
# Student <-> Section.
route([(745,500),(970,600)])
route([(1130,600),(1220,650)])
# Section <-> Assignment.
route([(745,500),(875,440)])
route([(1025,440),(1115,200)])
# Student <-> Assignment, with result attributes.
route([(1300,620),(1300,454)])
route([(1300,386),(1300,280),(1240,230)])
route([(1380,420),(1400,470)])
route([(1380,420),(1400,350)])

# Attribute edges.
for target in [(100,1000),(350,1000)]:
    route([(250,880),target])
for target in [(750,1000),(1000,1000)]:
    route([(850,880),target])
route([(1350,680),(1480,850)])
route([(1380,650),(1480,750)])
route([(1380,650),(1480,650)])
for target in [(100,90),(300,90),(500,90)]:
    route([(250,170),target])
for target in [(350,350),(550,350),(750,350),(950,350)]:
    route([(650,465),target])
for target in [(1000,90),(1200,90),(1400,90)]:
    route([(1200,170),target])

# Entity rectangles.
entity(250,850,'Professor')
entity(850,850,'Department',180)
entity(1300,650,'Student',160)
entity(650,500,'Section (Teach)',190,70)
entity(250,200,'Course')
entity(1200,200,'Assignment',170,60,weak=True)

# Relationship diamonds.
diamond(550,900,'WorksIn')
diamond(550,800,'Manages')
diamond(300,650,'Teaches')
diamond(850,680,'Offers')
diamond(1100,850,'BelongsTo')
diamond(300,400,'HasSection')
diamond(1050,600,'Enroll')
diamond(950,440,'Contains',150,68,identifying=True)
diamond(1300,420,'Assign')

# Attributes: key underlines and Assignment's dashed partial key.
attr(100,1000,'pid',100,key=True)
attr(350,1000,'name',140)
attr(750,1000,'did',100,key=True)
attr(1000,1000,'name',140)
attr(1480,850,'sid',100,key=True)
attr(1480,750,'name',140)
attr(1480,650,'unitrequirement',190)
attr(100,90,'cid',100,key=True)
attr(300,90,'coursenumber',180)
attr(500,90,'unit',100)
attr(350,350,'pid',100,key=True)
attr(550,350,'cid',100,key=True)
attr(750,350,'sectionnumber',190,key=True)
attr(950,350,'term',120,key=True)
attr(1000,90,'id',100,partial=True)
attr(1200,90,'weight',130)
attr(1400,90,'duedate',150)
attr(1470,470,'grade',140)
attr(1470,350,'turnindate',160)

# (Minimum, maximum) participation/cardinality at each endpoint.
for x,y,value in [
 (380,900,'(0, N)'),(700,920,'(1, N)'),
 (380,790,'(0, N)'),(700,775,'(1, 1)'),
 (235,745,'(0, N)'),(465,575,'(1, 1)'),
 (900,760,'(0, N)'),(780,590,'(1, 1)'),
 (980,875,'(0, N)'),(1260,750,'(1, 1)'),
 (235,300,'(0, N)'),(455,455,'(1, 1)'),
 (820,560,'(0, N)'),(1175,645,'(0, N)'),
 (810,490,'(0, N)'),(1115,300,'(1, 1)'),
 (1330,540,'(0, N)'),(1340,280,'(0, N)'),
]:
    card(x,y,value)

# Title and concise constraints that do not fit standard relationship notation.
c.setFont('Helvetica-Bold',23)
c.drawString(40,1062,'CS166 Grade Database - ER Diagram')
c.setFont('Helvetica',13)
c.drawString(40,1037,'Underlined: key. Dashed underline: partial key. Double shapes: weak entity / identifying relationship. Labels: (min, max).')
c.setFont('Helvetica',12)
c.drawString(40,39,'Section is the Teach table. Key: (pid, cid, sectionnumber, term). Assignment key: section key + id. Results require enrollment in the same section.')
c.drawString(40,21,'Managers and section professors must have WorksIn membership. Manages supplies manageby; Offers supplies dept. Grades and weights are percentages.')
c.showPage()
c.save()
print(OUTPUT)
