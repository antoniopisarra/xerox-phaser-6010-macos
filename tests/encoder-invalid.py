#!/usr/bin/env python3
"""Invalid raster inputs must fail quickly, rather than become successful/blank jobs."""
from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[1]
output=root/'build/tests'
output.mkdir(parents=True,exist_ok=True)
encoder=output/'encoder-invalid'
subprocess.run(['xcrun','clang','-O1','-g','-fsanitize=address','-fno-omit-frame-pointer',str(root/'src/foo2hbpl1.c'),'-o',str(encoder)],check=True)
cases=[b'',b'garbage',b'P5\n1 1\n255\n\xff',b'P5\n512 128\n255\n'+bytes(20),b'P5\n99999999999999999999 1\n255\n',b'P5\n6001 1\n255\n',b'P5\n512 10001\n255\n',b'P7\nWIDTH 512\nHEIGHT 128\nDEPTH 4\nMAXVAL 255\nENDHDR\n',b'P7\nWIDTH 9999999999999999\nHEIGHT 1\nDEPTH 4\nMAXVAL 255\nTUPLTYPE CMYK\nENDHDR\n']
for i,data in enumerate(cases):
 r=subprocess.run([str(encoder),'-z1','-m1','-A','-B'],input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=3)
 assert r.returncode==1,(i,r.returncode)
 assert b'AddressSanitizer' not in r.stderr,(i,r.stderr[:200])
 assert not r.stdout,(i,'partial output')
print(f'PASS: {len(cases)} malformed/oversized/truncated raster cases rejected without output or sanitizer errors.')
