#!/bin/bash
# Offline bridge conversion checks. No IPP server and no printer connection.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/airprint-tests
out=$(mktemp -d "$PWD/build/airprint-tests/output.XXXXXXXX")
trap 'rm -rf "$out"' EXIT
export PHASER_AIRPRINT_DRY_RUN_DIR="$out"
export PPD="$PWD/packaging/Phaser6010.ppd" IPP_COPIES=1 IPP_SIDES=one-sided
CONTENT_TYPE=application/pdf ./airprint/print-job.sh app/Resources/Calibration-en.pdf
xcrun clang -Wno-deprecated-declarations tests/airprint-raster.c -lcups -o build/airprint-tests/raster
build/airprint-tests/raster > build/airprint-tests/test.urf
CONTENT_TYPE=image/urf ./airprint/print-job.sh build/airprint-tests/test.urf
count=$(find "$out" -type f | wc -l | tr -d ' ')
[[ $count == 2 ]]
for f in "$out"/*; do
 [[ $(head -c 4 "$f") == '%!PS' ]]
 vendor/ghostscript/bin/gs -q -dBATCH -dNOPAUSE -sDEVICE=nullpage "$f"
done
if CONTENT_TYPE=image/urf ./airprint/print-job.sh /dev/null; then exit 1; fi
[[ $(find "$out" -type f | wc -l | tr -d ' ') == 2 ]]
echo 'PASS: PDF and Apple Raster convert to valid PostScript; invalid raster rejected; no queue submission.'
