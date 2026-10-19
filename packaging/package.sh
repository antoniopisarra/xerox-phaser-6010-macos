#!/bin/bash
# Creates the unsigned distribution with standalone Ghostscript and corresponding source.
set -euo pipefail
export COPYFILE_DISABLE=1
cd "$(dirname "$0")/.."
version=$(tr -d '\r\n' < VERSION)
./packaging/build.sh
mkdir -p dist
[[ -x vendor/ghostscript/bin/gs ]] || { echo 'Manca vendor/ghostscript: serve una build autonoma con risorse e licenze.' >&2; exit 1; }
[[ -d vendor/corresponding-source && -f vendor/THIRD-PARTY-NOTICES ]] || { echo 'Mancano sorgenti corrispondenti e inventario licenze.' >&2; exit 1; }
# Reject absolute non-system libraries; @rpath dependencies require a separate relocation audit.
find vendor/ghostscript -type f -print0 | while IFS= read -r -d '' f; do
 if file "$f" | grep -q 'Mach-O'; then
  if otool -L "$f" | tail -n +2 | grep -E '/opt/homebrew|/usr/local|/Users/'; then
   echo "Dipendenze non autonome: $f" >&2; exit 1
  fi
 fi
done
root=$(mktemp -d /private/tmp/phaser6010-payload.XXXXXXXX)
trap 'rm -rf "$root"' EXIT
dest="$root/Library/Printers/Phaser6010"
mkdir -p "$dest/bin" "$dest/filter" "$dest/licenses" "$root/Applications"
cp build/bin/foo2hbpl1 "$dest/bin/"
# Production filter has no development override.
sed '/^if \[\[ ${PHASER_DEVELOPMENT/d' filter/phaser6010 > "$dest/filter/phaser6010"
chmod 755 "$dest/filter/phaser6010"
cp packaging/uninstall.sh "$dest/"
cp packaging/Phaser6010.ppd "$dest/"
cp -R vendor/ghostscript "$dest/gs"
mkdir -p "$dest/licenses/project-source"
cp -R src filter app design packaging scripts tests docs README.md README.it.md LICENSE VERSION CHANGELOG.md "$dest/licenses/project-source/"
cp -R vendor/original-encoder "$dest/licenses/"
cp -R vendor/corresponding-source "$dest/licenses/"
cp vendor/THIRD-PARTY-NOTICES vendor/COPYING-foo2hbpl1 vendor/LICENSE-Ghostscript vendor/COPYING-Ghostscript-AGPL vendor/DroidSansFallback.NOTICE "$dest/licenses/"
cp -R 'build/Configura Xerox Phaser 6010N.app' "$root/Applications/"
find "$root" -type d -exec chmod 755 {} +
find "$root" -type f -exec chmod go-w {} +
find "$root" -name '._*' -type f -delete
xattr -cr "$root"
codesign --verify --deep --strict "$root/Applications/Configura Xerox Phaser 6010N.app"
# A development copy with the same bundle ID must never redirect installation.
pkgbuild --analyze --root "$root" build/components.plist
/usr/bin/plutil -replace 0.BundleIsRelocatable -bool NO build/components.plist
/usr/bin/plutil -replace 0.BundleHasStrictIdentifier -bool YES build/components.plist
pkgbuild --component-plist build/components.plist --ownership recommended --root "$root" --identifier org.community.phaser6010 --version "$version" --install-location / build/Phaser6010-component.pkg

sed "s/version=\"1.0.0\"/version=\"$version\"/" packaging/Distribution.xml > build/Distribution.xml
productbuild --distribution build/Distribution.xml --resources packaging/resources --package-path build "dist/Driver-Xerox-Phaser-6010N-macOS-$version.pkg"
