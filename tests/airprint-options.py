#!/usr/bin/env python3
"""Exercise actual conversion boundary and planned local queue options without lp."""
from pathlib import Path
import os,subprocess,tempfile
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(dir=root/'build',prefix='options-') as temp:
 out=Path(temp)
 base=dict(os.environ,PHASER_AIRPRINT_DRY_RUN_DIR=temp,PPD=str(root/'packaging/Phaser6010.ppd'),IPP_SIDES='one-sided')
 def run(file,mime,extra):
  old=set(out.glob('*.options'))
  env=dict(base,CONTENT_TYPE=mime,**extra)
  r=subprocess.run([str(root/'airprint/print-job.sh'),str(file)],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=10)
  new=set(out.glob('*.options'))-old
  return r,dict(line.split('=',1) for line in next(iter(new)).read_text().splitlines()) if new else None
 raster=root/'build/airprint-tests/test.urf'
 assert raster.exists(),'Run tests/airprint.sh first'
 r,options=run(raster,'image/urf',{'IPP_COPIES':'2','IPP_MEDIA_COL':'{media-size={y-dimension=27940 x-dimension=21590}}','IPP_PRINT_COLOR_MODE':'monochrome'})
 assert r.returncode==0,r.stderr[-300:]
 assert options=={'PageSize':'Letter','Copies':'2','ColorModel':'Gray'},options
 r,options=run(raster,'image/urf',{'IPP_MEDIA_COL':'{media-size-name=iso_a4_210x297mm}'})
 assert r.returncode==0 and options['PageSize']=='A4'
 for extra in [{'IPP_COPIES':'0'},{'IPP_COPIES':'9999'},{'IPP_MEDIA_COL':'{media-size={x-dimension=210000 y-dimension=297000}}'},{'IPP_MEDIA':'Letter','IPP_MEDIA_COL':'{media-size-name=iso_a4_210x297mm}'}]:
  r,options=run(raster,'image/urf',extra)
  assert r.returncode!=0 and options is None,(extra,r.stderr)
 r,options=run(root/'app/Resources/Calibration-en.pdf','application/pdf',{'IPP_COPIES':'2'})
 assert r.returncode==0 and options['Copies']=='1' # PDF converter expanded copies already.
 # A nonempty but incomplete URF must not become a successful partial print.
 bad=out/'truncated.urf'
 content=raster.read_bytes();bad.write_bytes(content[:len(content)//2])
 r,options=run(bad,'image/urf',{})
 assert r.returncode!=0 and options is None
print('PASS: raster copies, Letter/name-only/reversed media, grayscale queue mode, invalid options and PDF copy handling.')
