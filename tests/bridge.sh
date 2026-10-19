#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/bridge-tests/runtime/airprint
cp packaging/Phaser6010.ppd build/bridge-tests/runtime/
cp airprint/print-job.sh build/bridge-tests/runtime/airprint/
xcrun swiftc -module-cache-path "$PWD/build/module-cache" app/Language.swift app/Calibration.swift app/Discovery.swift app/PrinterStatus.swift app/AirPrint.swift tests/bridge/main.swift -o build/bridge-tests/controller
build/bridge-tests/controller "$PWD/build/bridge-tests/runtime" "$PWD/app/Resources/Calibration-en.pdf"
