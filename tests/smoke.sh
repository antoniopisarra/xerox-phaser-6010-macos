#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GS_EXECUTABLE:?Set absolute path to development Ghostscript}"
./packaging/build.sh
runtime="$PWD/build/test-runtime"
mkdir -p "$runtime/bin" "$runtime/gs/bin"
cp build/bin/foo2hbpl1 "$runtime/bin/"
ln -sf "$GS_EXECUTABLE" "$runtime/gs/bin/gs"
gs_root="$(cd "$(dirname "$GS_EXECUTABLE")/.." && pwd)"
if [[ ! -e "$runtime/gs/share" && -d "$gs_root/share" ]]; then ln -s "$gs_root/share" "$runtime/gs/share"; fi
export PHASER_DEVELOPMENT=1 PHASER_ROOT="$runtime"
"$GS_EXECUTABLE" -q -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=build/test.pdf tests/two-pages.ps
./filter/phaser6010 1 test test 1 'PageSize=A4 ColorModel=CMYK' build/test.pdf > build/color.hbpl
./filter/phaser6010 2 test test 1 'PageSize=Letter ColorModel=Gray' tests/two-pages.ps > build/gray.hbpl
printf 'not a document' > build/invalid-document
if ./filter/phaser6010 3 test test 1 '' build/invalid-document > build/invalid.hbpl 2> build/invalid.log; then
 echo 'ERROR: invalid document accepted'; exit 1
fi
[[ ! -s build/invalid.hbpl ]]
if ./filter/phaser6010 4 test test '1;id' '' tests/two-pages.ps > build/invalid-copy.hbpl; then exit 1; fi
[[ ! -s build/invalid-copy.hbpl ]]
[[ -s build/color.hbpl && -s build/gray.hbpl ]]
/usr/bin/cupstestppd -I filters packaging/Phaser6010.ppd
echo 'PASS: conversion PDF/PS, color/gray; invalid input/copies reject without print output.'
