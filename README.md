# Xerox Phaser 6010N for macOS

Made by [Logical Flow](https://www.logicalflow.it/en/).

[Italiano](README.it.md) · [Download the installer](https://github.com/antoniopisarra/xerox-phaser-6010-macos/releases/latest)

<img src="app/Resources/AppIcon.png" width="110" alt="Phaser 6010N setup icon">

## Why this project?

The Xerox Phaser 6010N can still print well, but its original software belongs to an earlier generation of computers. Xerox provides Windows drivers and legacy Mac drivers; those older Mac packages do not provide a working native Apple Silicon setup for the configuration tested here. This independent project brings the printer to modern Macs with a native ARM64 driver, a graphical setup application and a self-contained installer. No Terminal or Homebrew is needed to install or use it.

The target is Apple Silicon Macs — M1, M2, M3, M4, M5 and M6 families — running **macOS 26 or later**. This describes the ARM64 build target, not a physical test on every chip or future macOS release. Printing was physically tested on an Apple Silicon Mac reported as macOS 26.6.2. See [testing](docs/TESTING.md) for the distinction between tested behavior and remaining checks. Consult [Xerox's official downloads](https://www.support.xerox.com/en-us/product/phaser-6010/downloads) for vendor support.

**Only the Xerox Phaser 6010N connected by Ethernet is supported.** The Mac can use Wi-Fi on the same local network. USB, Intel Macs and other printer models are outside this release's support. With 1.3.0, the owner confirmed iPhone discovery and physical printing while the Mac is locked. Closing the MacBook lid interrupted sharing in the tested setup. See below.

## Install and print

1. Connect the printer by Ethernet to your router and turn it on.
2. Download `Driver-Xerox-Phaser-6010N-macOS-1.3.0.pkg` from [Releases](https://github.com/antoniopisarra/xerox-phaser-6010-macos/releases/latest), open it and choose the utility language on the customization page, then finish the installation.
3. Open **Configura Xerox Phaser 6010N** in **Applications**. Choose Italian or English during installation: check **English interface** for English, or leave it unchecked for Italian.
4. Allow local network access if macOS requests it. Select a discovered printer, or enter its IPv4 address, and add/update the printer. macOS requests administrator authorization to change the print queue.
5. Select **Xerox Phaser 6010N** in the usual macOS print dialog. Use A4 or Letter, plain paper, color or grayscale, single-sided printing.

The current installer is **not signed with an Apple Developer ID and is not notarized**. The application has an ad hoc integrity signature, which does not identify a verified developer. Gatekeeper may block the downloaded package. If you trust this project's release, follow macOS's **Privacy & Security → Open Anyway** procedure when offered. Organization policies may prevent installation. Do not disable Gatekeeper globally. Notarization is Apple's distribution security check; it is separate from successful printer testing.

The language choice applies to all users and takes effect at the next launch. Reinstall to change it; macOS system dialogs follow the system language.

## The utility pages

- **Printer / Stampante:** network discovery, manual IPv4 entry, queue creation/update and access to macOS printer settings.
- **Status and toner / Stato e toner:** printer state and cyan/magenta/yellow/black levels, manual refresh and automatic refresh every 30 seconds while this page is visible; printer web page, sharing settings and a diagnostic report export.
- **AirPrint:** start/stop the Mac-hosted bridge, service status and iPhone/iPad instructions.
- **Calibration / Calibrazione:** Italian/English calibration PDF, a print button, horizontal/vertical offsets, independent width/height corrections and a calculator based on actual paper measurements.

### Application screenshots

Real captures of version 1.1.0 installed on the test Mac, using the English interface. The utility also supports Italian.

**Printer — network discovery and IP setup**

![Printer discovered on the local network](docs/screenshots/printer.png)

**Status and toner — live printer readings**

![Ready printer and four toner levels](docs/screenshots/status-toner.png)

**Calibration — measurements, corrections and sheet printing**

![Calibration controls with PDF language selection](docs/screenshots/calibration.png)

**AirPrint — sharing with iPhone and iPad**

![AirPrint enabled in version 1.3.0](docs/screenshots/airprint.png)

Original capture of version 1.3.0 with AirPrint enabled, supplied by the owner. iPhone discovery and physical printing were confirmed with the Mac locked; closing the MacBook lid interrupted sharing in the tested setup.

The IP address, toner levels and calibration values belong to the test setup; they are not settings to copy. See [image details](docs/screenshots/README.md).

Toner readings come from the printer's SNMP interface and are estimates reported by its firmware. Unknown values remain unavailable. Discovery/status need UDP 161; printing uses TCP 9100. If SNMP or broadcast discovery is disabled, use a manual IP; unavailable toner reporting does not prevent printing. Status requires the macOS `snmpget` utility; the application reports an unavailable status if it is missing.

## Calibration

Open **Calibrazione**, select **Italiano** or **English**, then **Stampa foglio di centratura…**. Print A4 at **100%**, with no fit-to-page setting. The PDF has a 100 × 100 mm square and a frame 10 mm from each edge. Measure the printed paper, enter the dimensions/margins, calculate and save the correction. Print again to check it.

For example, left/right margins of 15/5 mm require moving content 5 mm left. An accurate 100 mm square means scale should stay at 100%. Positive X moves right; positive Y moves down. The calculator adjusts current corrections, so use measurements from the current settings. Offsets are limited to ±20 mm and scale to 50–150%; out-of-range measurements are rejected. Large corrections can clip content beyond the paper.

PDFs: [Italian](app/Resources/Centratura-it.pdf) · [English](app/Resources/Calibration-en.pdf).

## Updating, removal and sharing

Install a newer package over the previous one. It replaces application/driver files and preserves the local calibration settings. Use **Disinstalla…** in the utility to remove its application, driver, calibration and the `Phaser6010` queue, including jobs still in that queue. The utility asks for confirmation and administrator authorization.

The sharing button opens macOS sharing settings. Sharing is configured by the user and requires the Mac to remain on. Open **AirPrint → Enable AirPrint** to start the optional bridge. On iPhone/iPad, use **Share → Print → Select Printer → Xerox Phaser 6010N via Mac**. Keep the Mac on with a user logged in, on the same LAN. AirPrint now stays active when the utility closes and restarts at that user’s login. Use Disable AirPrint to stop it. Display sleep is allowed. Idle sleep is inhibited while sharing; manual sleep, closing the lid or shutting down still interrupts it. Anyone able to reach the service can submit jobs: use a trusted network. Installation does not enable sharing. Once enabled, a per-user launch agent starts it at login until you disable it. Local IPP/PDF/Apple Raster tests passed. After removing the previous package and installing 1.2.1, the owner confirmed successful physical printing from the iPhone. Other iOS versions, job options and Mac AirPrint clients still need separate testing. See [sharing](docs/SHARING.md).

## What changed from the working prototype?

The project retains the proven `foo2hbpl1` C encoder, adds a page-tail memory bounds fix, and replaces the Foomatic pipeline with a dedicated CUPS filter. A standalone Ghostscript converts PDF/PostScript to 600 dpi raster data before HBPLv1 encoding. The installer includes Ghostscript, fonts, color profiles, original sources and license notices. It does not rely on a Homebrew installation or modify the system Ghostscript.

The pipeline fixes the sandbox-sensitive temporary-file parsing and removes forced PDF fit-to-page behavior. Calibration is applied once per page. The native AppKit utility adds discovery, queue setup, toner monitoring, privacy-conscious diagnostics, bilingual calibration sheets and an application icon. The installer disables bundle relocation so an old development copy cannot capture the installation.

This uses the legacy CUPS PPD/filter interface available on the tested macOS release. The IPP server is compiled privately from pinned Apple CUPS source, with its source and Apache license/notices included; system CUPS remains untouched. The [AirPrint bridge](airprint/README.md) is available through an explicit enable/disable control; installation does not enable network sharing. Future macOS printing changes may require updates.

## Source, build and verification

Developers need an Apple Silicon Mac with Xcode/Command Line Tools. End users only need the package. See [build instructions](docs/BUILD.md), [architecture](docs/ARCHITECTURE.md), [test coverage](docs/TESTING.md) and [release procedure](docs/RELEASE.md).

```sh
./scripts/fetch-ghostscript.sh
./packaging/build-ghostscript.sh
./tests/core.sh
python3 tests/encoder-memory.py
GS_EXECUTABLE="$PWD/vendor/ghostscript/bin/gs" ./tests/smoke.sh
./packaging/package.sh
```

The release also provides a complete corresponding-source archive, including the pinned Ghostscript source, so the dependency can be rebuilt offline. The complete pinned Apple CUPS source is also included. Source URLs and SHA-256 verification are recorded in the fetch/build scripts. PDF/icon regeneration additionally uses Python with ReportLab and Apple Swift tools; generated assets are committed.

## Upstream project

The encoder derives from the Linux **[foo2zjs / foo2hbpl1 project](https://github.com/OpenPrinting/foo2zjs)**. It was not rewritten from scratch: this port preserves the original authors' work and adds the macOS pipeline, installer and utility. The supplied source credits **Robert Szalai, Rick Richardson, Dave Coffin and Joe Da Silva**. Thank you for making open-source HBPLv1 printing possible.

The actual input was the `foo2zjs-macos` directory supplied by the port's author, including the HBPLv1 changes recorded in its ChangeLog. Its original Git history was not included, so this copy is not attributed to an unverified upstream commit. See [provenance and changes](docs/UPSTREAM.md).

## Licenses and credits

Independent community project, unaffiliated with and not endorsed by Xerox. Xerox and Phaser are their owners' trademarks. No proprietary Xerox driver or firmware is bundled.

- Encoder and new project code: **GPL-2.0-or-later**; see [LICENSE](LICENSE). Original encoder authors and notices remain in [the source](src/foo2hbpl1.c), with an [unmodified reference](vendor/original-encoder/foo2hbpl1.c).
- Private IPP server: Apple CUPS, Apache-2.0 with upstream exceptions; see [license](vendor/LICENSE-CUPS), [notices](vendor/NOTICE-CUPS) and [provenance](docs/UPSTREAM.md).
- Ghostscript/GhostPDL 10.08.0: **AGPL-3.0-or-later**, Artifex and contributors. The GPL's “or later” option permits GPLv3 use where AGPLv3 compatibility is needed. Do not relicense Ghostscript as GPLv2-only.
- Bundled fonts/libraries retain their own notices; see [third-party inventory](vendor/THIRD-PARTY-NOTICES) and the complete source archive. The installed `/Library/Printers/Phaser6010/licenses` directory contains sources, build recipes and license texts.

Thanks to the upstream foo2hbpl1/foo2zjs contributors, Ghostscript contributors and the users testing the physical printer. Maintenance is community/best effort. Reports should include macOS version, chip family, connection type and the utility's diagnostic report. Do not attach private documents or unredacted print logs.

## Detailed code review

The [19 October review](docs/REVIEW-2026-10-19.md) records confirmed defects, fixes, benchmarks and remaining acceptance work. The owner confirmed iPhone discovery and printing with the Mac locked on 1.3.0. App-closed operation, login restart and new copy/media combinations still require separate acceptance.
