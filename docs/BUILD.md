# Build

Use Apple Silicon and macOS 26+, with Xcode or Command Line Tools selected by `xcode-select`. The build uses Apple's clang, Swift, AppKit, PDFKit, pkgbuild, productbuild and codesign. No Homebrew library is required. Python 3 is used for the memory regression test; ReportLab is needed only to regenerate committed PDFs.

1. `./scripts/fetch-ghostscript.sh` downloads the official GhostPDL 10.08.0 source, verifying its pinned SHA-256 before use. An existing matching archive is reused.
2. `./packaging/build-ghostscript.sh` builds ARM64 Ghostscript from source with bundled libraries and no CUPS, fontconfig, GTK, X11 or Tesseract dependency. It stages fonts, resources and ICC profiles under `vendor/ghostscript`. To rebuild, remove the previous `build/ghostscript-source` directory first.
3. `./packaging/build.sh` compiles the encoder and the Swift application, copies committed assets and applies an ad hoc integrity signature. Nothing is installed.
4. Run the checks in TESTING.md.
5. `./packaging/package.sh` builds the versioned package in `dist/`. It includes corresponding source and audits Mach-O dependencies for developer/Homebrew paths. It uses a non-relocatable application component and root-owned payload.

`VERSION` determines application and package versions. The minimum OS is 26.0. The application uses the host Swift toolchain; build only on ARM64. Two mutually exclusive, script-only language components write the chosen interface language (Italian by default, English when selected). Packages do not print, create a queue or overwrite calibration. The user configures the queue in the app after installation.

## Assets

`design/build-assets.sh` regenerates the icon using AppKit and the ICNS packer. `python3 design/create-calibration.py` regenerates both committed PDFs with ReportLab. Verify A4 size and render both before release. Neither tool is needed by users.

## Offline source archive

Unpack the release's complete corresponding-source archive and follow the same instructions. Its `vendor/corresponding-source/ghostpdl-10.08.0.tar.xz` is already included; the fetch step only checks its hash. The installed licenses/project-source directory also carries project sources; the adjacent corresponding-source directory holds the original dependency archive. Place that archive at the documented vendor path before a rebuild from an installed copy.

## Private IPP server (1.2.1+)

`packaging/build.sh` also calls `packaging/build-ipp-server.sh`. The script verifies the pinned Apple CUPS archive using `scripts/fetch-cups.sh`, configures headers in build/cups-source and compiles only tools/ippeveprinter.c against native macOS libcups. No system library, daemon or executable is replaced. A fresh checkout needs network access for this 8 MB source download; release corresponding-source archives include it for offline builds. The executable is installed as bin/phaser-ipp-server. No source patches are applied.
