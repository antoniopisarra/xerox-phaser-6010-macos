#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/fetch-cups.sh
mkdir -p build/bin
if [[ ! -f build/cups-source/config.h ]]; then
 mkdir -p build/cups-source
 tar -xzf vendor/corresponding-source/cups-a8968fc.tar.gz --strip-components=1 -C build/cups-source
 (cd build/cups-source && PATH=/usr/bin:/bin:/usr/sbin:/sbin CC=/usr/bin/clang CXX=/usr/bin/clang++ ./configure --disable-shared --disable-pam --disable-gssapi --disable-libusb) > build/cups-configure.log 2>&1
fi
# Reapply the tracked bridge policy to pristine pinned source on every build.
entry=$(tar -tzf vendor/corresponding-source/cups-a8968fc.tar.gz | /usr/bin/sed -n '\|/tools/ippeveprinter[.]c$|p')
[[ -n "$entry" ]]
tar -xOf vendor/corresponding-source/cups-a8968fc.tar.gz "$entry" > build/cups-source/tools/ippeveprinter.c
/usr/bin/patch --batch -p1 -d build/cups-source < packaging/ipp-server.patch > build/cups-patch.log
# Only build the IPP application. The macOS printing system/libraries are untouched.
MACOSX_DEPLOYMENT_TARGET=26.0 xcrun clang -arch arm64 -O2 -Wno-deprecated-declarations \
 -Ibuild/cups-source -Ibuild/cups-source/tools build/cups-source/tools/ippeveprinter.c -lcups -o build/bin/phaser-ipp-server
codesign --force --sign - build/bin/phaser-ipp-server
