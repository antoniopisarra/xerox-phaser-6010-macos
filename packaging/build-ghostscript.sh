#!/bin/bash
# Offline build from the original verified release, using Apple tools and bundled libs.
set -euo pipefail
cd "$(dirname "$0")/.."
archive="$PWD/vendor/corresponding-source/ghostpdl-10.08.0.tar.xz"
expected=94943e3c4adb7115d132b3c28b913672f2e62e6a9d802f7e754e716b1634174a
[[ $(shasum -a 256 "$archive" | awk '{print $1}') == "$expected" ]]
mkdir -p build/ghostscript-source
# Use a fresh build directory to avoid hidden Homebrew configuration.
[[ ! -e build/ghostscript-source/ghostpdl-10.08.0 ]] || { echo 'Remove previous build/ghostscript-source before rebuilding.' >&2; exit 1; }
tar -xf "$archive" -C build/ghostscript-source
cd build/ghostscript-source/ghostpdl-10.08.0
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
export CC=clang CXX=clang++ CFLAGS='-O2 -arch arm64' LDFLAGS='-arch arm64'
./configure --prefix=/Library/Printers/Phaser6010/gs --disable-cups --disable-gtk --disable-fontconfig --without-tesseract --without-libidn --without-libpaper --without-ijs --without-x
make -j6
make install DESTDIR="$PWD/../stage"
cd ../../..
mkdir -p vendor/ghostscript/bin
cp build/ghostscript-source/ghostpdl-10.08.0/bin/gs vendor/ghostscript/bin/
cp -R build/ghostscript-source/stage/Library/Printers/Phaser6010/gs/share vendor/ghostscript/
cp -R build/ghostscript-source/ghostpdl-10.08.0/Resource vendor/ghostscript/share/ghostscript/10.08.0/
cp -R build/ghostscript-source/ghostpdl-10.08.0/iccprofiles vendor/ghostscript/share/ghostscript/10.08.0/
otool -L vendor/ghostscript/bin/gs
