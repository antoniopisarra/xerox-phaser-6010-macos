#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/iconset.iconset build/module-cache
xcrun swiftc -module-cache-path "$PWD/build/module-cache" design/create-icon.swift -o build/create-icon
build/create-icon app/Resources/AppIcon.png
for icon_size in 16 32 128 256 512; do
 sips -z "$icon_size" "$icon_size" app/Resources/AppIcon.png --out "build/iconset.iconset/icon_${icon_size}x${icon_size}.png" >/dev/null
 retina_size=$((icon_size*2))
 sips -z "$retina_size" "$retina_size" app/Resources/AppIcon.png --out "build/iconset.iconset/icon_${icon_size}x${icon_size}@2x.png" >/dev/null
done
"${PYTHON_FOR_ASSETS:-python3}" design/pack-icon.py build/iconset.iconset app/Resources/AppIcon.icns
"${PYTHON_FOR_ASSETS:-python3}" design/create-calibration.py
