#!/bin/bash
set -euo pipefail
export COPYFILE_DISABLE=1
export MACOSX_DEPLOYMENT_TARGET=26.0
cd "$(dirname "$0")/.."
version=$(tr -d '\r\n' < VERSION)
[[ $version =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]] || exit 1
stage=$(mktemp -d /private/tmp/phaser6010-app.XXXXXXXX)
trap 'rm -rf "$stage"' EXIT
appdir="$stage/Configura Xerox Phaser 6010N.app"
mkdir -p build/bin "$appdir/Contents/MacOS"
./packaging/build-ipp-server.sh
xcrun clang -arch arm64 -O2 -Wall -Wno-deprecated-declarations src/check-raster.c -lcups -o build/bin/phaser-check-raster
xcrun clang -arch arm64 -O2 -Wall src/foo2hbpl1.c -o build/bin/foo2hbpl1
xcrun swiftc -module-cache-path "$PWD/build/module-cache" -O -framework Cocoa -framework PDFKit app/*.swift -o "$appdir/Contents/MacOS/ConfiguraPhaser"
cat > "$appdir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>org.community.phaser6010.setup</string><key>CFBundleExecutable</key><string>ConfiguraPhaser</string><key>CFBundleName</key><string>Configura Xerox Phaser 6010N</string><key>CFBundleVersion</key><string>1.0.0</string><key>NSPrincipalClass</key><string>NSApplication</string></dict></plist>
PLIST
mkdir -p "$appdir/Contents/Resources"
cp app/Resources/* "$appdir/Contents/Resources/"
/usr/bin/plutil -replace CFBundleVersion -string "$version" "$appdir/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleShortVersionString -string "$version" "$appdir/Contents/Info.plist"
/usr/bin/plutil -insert CFBundleIconFile -string AppIcon "$appdir/Contents/Info.plist"
/usr/bin/plutil -insert NSLocalNetworkUsageDescription -string "Cerca le Xerox Phaser 6010 sulla tua rete locale per configurare la stampa." "$appdir/Contents/Info.plist"
/usr/bin/plutil -insert NSBonjourServices -json '["_pdl-datastream._tcp", "_printer._tcp", "_ipp._tcp", "_ipps._tcp"]' "$appdir/Contents/Info.plist"
xattr -cr "$appdir"
codesign --force --sign - "$appdir"
codesign --verify --deep --strict "$appdir"
rm -rf 'build/Configura Xerox Phaser 6010N.app'
cp -R "$appdir" build/
echo 'Build locale completata. Nessun componente installato.'
