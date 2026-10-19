#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
xcrun swiftc -module-cache-path "$PWD/build/module-cache" app/Calibration.swift app/Discovery.swift app/PrinterStatus.swift app/Diagnostics.swift tests/core/main.swift -o build/tests/core
build/tests/core
