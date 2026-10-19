#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
cd "$(dirname "$0")/.."
archive=vendor/corresponding-source/cups-a8968fc.tar.gz
expected=72cc272eb95dac3b8f5914ce727e9ee454a2aa10a56ca954cfc66899eb236624
mkdir -p vendor/corresponding-source
if [[ ! -f "$archive" ]]; then
 trap 'rm -f "$archive.download"' EXIT
 curl --fail --location --retry 3 --proto '=https' 'https://codeload.github.com/apple/cups/legacy.tar.gz/a8968fc4257322b1e4e191c4bccedea98d7b053e' -o "$archive.download"
 [[ $(shasum -a 256 "$archive.download" | awk '{print $1}') == "$expected" ]] || { echo 'CUPS checksum mismatch' >&2; exit 1; }
 mv "$archive.download" "$archive"
fi
[[ $(shasum -a 256 "$archive" | awk '{print $1}') == "$expected" ]]
