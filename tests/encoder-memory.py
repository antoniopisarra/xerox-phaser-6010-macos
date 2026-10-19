#!/usr/bin/env python3
"""Synthetic regression coverage for encoder page-tail bounds; no printer access."""
from pathlib import Path
import os
import random
import subprocess

project = Path(__file__).resolve().parents[1]
output = project / 'build' / 'memory-tests'
output.mkdir(parents=True, exist_ok=True)
encoder = output / 'foo2hbpl1-asan'
subprocess.run(['xcrun', 'clang', '-O2', '-g', '-fsanitize=address',
                '-fno-omit-frame-pointer', str(project/'src/foo2hbpl1.c'),
                '-o', str(encoder)], check=True)
rng = random.Random(6010)
cases = [(512,128,1,'blank'), (512,128,4,'blank'),
         (4960,7016,4,'blank'), (4960,7016,4,'saturated')]
cases += [(512,128,d,'pattern') for d in (1,4) for _ in range(6)]
for number,(width,height,depth,kind) in enumerate(cases,1):
    if kind == 'pattern':
        data = bytearray(width*height*depth)
        for y in range(height):
            for x in range(width):
                v = 0 if y > height-24 else rng.choice((0,0,255,127))
                for c in range(depth):
                    data[(y*width+x)*depth+c] = v
    else:
        value = 255 if kind == 'saturated' or depth == 1 else 0
        data = bytes([value]) * (width*height*depth)
    header = (f'P7\nWIDTH {width}\nHEIGHT {height}\nDEPTH 4\nMAXVAL 255\nTUPLTYPE CMYK\nENDHDR\n'
              if depth == 4 else f'P5\n{width} {height}\n255\n').encode()
    result = subprocess.run([str(encoder),'-z1','-m1','-A','-B'],
                            input=header+data, stdout=subprocess.DEVNULL,
                            stderr=subprocess.PIPE,
                            env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
    if result.returncode or result.stderr:
        raise RuntimeError(f'case {number}: {result.stderr.decode(errors="replace")}')
    print(f'PASS {number}: {width}x{height}, depth {depth}, {kind}')
print('PASS: 16 AddressSanitizer cases; no print job submitted.')
