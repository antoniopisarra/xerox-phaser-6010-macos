# SPDX-License-Identifier: GPL-2.0-or-later
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
LANGUAGES={
 'it':dict(file='Centratura-it.pdf',title='Calibrazione di stampa.',subtitle='Xerox Phaser 6010N / Foglio A4 di calibrazione',
 steps=['1. Stampa al 100%, su A4. Disattiva Adatta alla pagina.','2. Misura il quadrato e le distanze della cornice dai quattro bordi del foglio.','3. Inserisci le misure in Calibrazione, calcola e salva le correzioni.'],
 goal='Obiettivo: quadrato 100 x 100 mm e cornice a 10 mm dai quattro bordi.',measure='Misura tra i centri delle linee',guide='COME LEGGERE LE MISURE',
 notes=['Larghezza o altezza diversa da 100 mm: correggi la scala del relativo asse.','Margini sinistro / destro di 15 / 5 mm: sposta 5 mm a sinistra (-5 mm).','Margini sopra / sotto di 15 / 5 mm: sposta 5 mm verso l’alto (+5 mm).','Le nuove correzioni vengono calcolate rispetto alla calibrazione gia salvata.','Se il quadrato e 100 x 100 mm, lascia invariata la scala: correggi solo la posizione.'],
 fields=['Larghezza: ____ mm   Altezza: ____ mm','Sinistra: ____   Destra: ____   Sopra: ____   Sotto: ____ mm']),
 'en':dict(file='Calibration-en.pdf',title='Print alignment check.',subtitle='Xerox Phaser 6010N / A4 calibration sheet',
 steps=['1. Print at 100% on A4 paper. Turn off Scale to Fit.','2. Measure the square and the frame distance from all four paper edges.','3. Enter the measurements in Calibration, calculate and save the corrections.'],
 goal='Target: a 100 x 100 mm square and a frame 10 mm from every paper edge.',measure='Measure between the centres of the lines',guide='HOW TO READ THE MEASUREMENTS',
 notes=['If either side is not 100 mm, adjust the scale for that axis.','Left / right margins of 15 / 5 mm: move 5 mm left (-5 mm).','Top / bottom margins of 15 / 5 mm: move 5 mm up (+5 mm).','New corrections are calculated relative to the calibration already saved.','If the square is 100 x 100 mm, keep the scale unchanged and adjust position only.'],
 fields=['Width: ____ mm   Height: ____ mm','Left: ____   Right: ____   Top: ____   Bottom: ____ mm'])
}
for language,t in LANGUAGES.items():
 target=ROOT/'app/Resources'/t['file'];c=canvas.Canvas(str(target),pagesize=A4)
 c.setTitle(t['title']);c.setAuthor('xerox-phaser-6010-macos contributors')
 ink=HexColor('#15384b');teal=HexColor('#047e8b');gray=HexColor('#51616a')
 def text(x,y,s,size=10,color=ink,bold=False):
  c.setFillColor(color);c.setFont('Helvetica-Bold' if bold else 'Helvetica',size);c.drawString(x*mm,y*mm,s)
 c.setStrokeColor(HexColor('#364c59'));c.setLineWidth(.2*mm);c.rect(10*mm,10*mm,190*mm,277*mm)
 text(20,273,t['title'],22,bold=True);text(20,263,t['subtitle'],10,teal)
 for y,s in zip([251,244,237],t['steps']):text(20,y,s,10)
 text(20,225,t['goal'],9.7,bold=True)
 c.setStrokeColor(ink);c.setLineWidth(.3*mm);c.rect(55*mm,106*mm,100*mm,100*mm)
 c.setFillColor(ink);c.setFont('Helvetica-Bold',18);c.drawCentredString(105*mm,158*mm,'100 x 100 mm')
 c.setFont('Helvetica',9);c.drawCentredString(105*mm,150*mm,t['measure'])
 c.setLineWidth(.2*mm)
 for x in [55,155]:c.line((x-2)*mm,156*mm,(x+2)*mm,156*mm)
 for y in [106,206]:c.line(105*mm,(y-2)*mm,105*mm,(y+2)*mm)
 text(20,91,t['guide'],9,teal,True)
 for y,s in zip([81,73,65,53,45],t['notes']):text(20,y,s,9.1,gray)
 text(20,26,t['fields'][0],9);text(20,19,t['fields'][1],9)
 c.showPage();c.save();print(target)
