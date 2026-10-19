#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(tr -d '\r\n' < VERSION)
[[ -f "dist/Driver-Xerox-Phaser-6010N-macOS-$version.pkg" ]]
./scripts/fetch-ghostscript.sh
stage=$(mktemp -d /private/tmp/phaser6010-source.XXXXXXXX)
trap 'rm -rf "$stage"' EXIT
name="xerox-phaser-6010-macos-$version-source"
mkdir -p "$stage/$name/vendor/corresponding-source"
git archive HEAD | tar -xf - -C "$stage/$name"
cp vendor/corresponding-source/ghostpdl-10.08.0.tar.xz "$stage/$name/vendor/corresponding-source/"
COPYFILE_DISABLE=1 tar -czf "dist/$name.tar.gz" -C "$stage" "$name"
cp app/Resources/Centratura-it.pdf app/Resources/Calibration-en.pdf dist/
(cd dist && shasum -a 256 "Driver-Xerox-Phaser-6010N-macOS-$version.pkg" "$name.tar.gz" Centratura-it.pdf Calibration-en.pdf > SHA256SUMS)
