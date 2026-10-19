#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
archive=vendor/corresponding-source/ghostpdl-10.08.0.tar.xz
expected=94943e3c4adb7115d132b3c28b913672f2e62e6a9d802f7e754e716b1634174a
mkdir -p vendor/corresponding-source
if [[ ! -f "$archive" ]]; then
 trap 'rm -f "$archive.download"' EXIT
 curl --fail --location --retry 3 --proto '=https' 'https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10080/ghostpdl-10.08.0.tar.xz' -o "$archive.download"
 [[ $(shasum -a 256 "$archive.download" | awk '{print $1}') == "$expected" ]] || { echo 'Ghostscript checksum mismatch' >&2; exit 1; }
 mv "$archive.download" "$archive"
fi
[[ $(shasum -a 256 "$archive" | awk '{print $1}') == "$expected" ]] || { echo 'Ghostscript checksum mismatch' >&2; exit 1; }
echo 'Ghostscript source checksum verified.'
