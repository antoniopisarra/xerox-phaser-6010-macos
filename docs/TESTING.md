# Verification and physical testing

## Confirmed during development

The owner physically printed with the Ethernet Phaser 6010N on an ARM64 Mac reported as macOS 26.6.2: text, color images and PDFs from Preview, including an invoice. Printing became immediate after the filter fixes. A printed 100 × 100 mm square measured 100 × 100 mm after removal of forced fit-to-page. Unequal horizontal frame margins were reported (15 mm left, 5 mm right); the utility supplies a -5 mm correction, but the final physical centering after that correction has not been explicitly confirmed.

Live discovery and SNMP status were checked against the real printer. Toner calculations returned cyan 5%, magenta 10%, yellow 30%, black 100% in that snapshot. These are time-specific device readings, not fixed expected values for future runs.

## Automated checks

- `./tests/core.sh`: calibration parsing, migration, ranges, measured correction math, address/model checks, malformed SNMP, toner parsing/unknown values and diagnostic privacy checks.
- `python3 tests/encoder-memory.py`: 16 synthetic color/gray page patterns, including A4 page tails and blank/saturated pages under AddressSanitizer.
- `GS_EXECUTABLE="$PWD/vendor/ghostscript/bin/gs" ./tests/smoke.sh`: build, multipage PDF/PostScript conversion, color/A4 and gray/Letter output, rejection of malformed input/copy arguments without output, PPD validation.
- Package build: architecture/dependency inspection, application signature integrity, non-relocatable bundle metadata, original dependency source and licenses included.

These checks do not send print jobs. Test output files are under ignored build/. CI runs without a printer.

## Release acceptance on the Mac

The final 1.0.0 interface cannot be visually accepted through this automation environment: macOS denied GUI automation/application registration. It still needs a normal desktop launch and three real screenshots. The owner will supply them. Compilation and core tests cannot replace these checks:

1. Install the downloaded package on a clean ARM64 Mac; observe actual Gatekeeper behavior. Open the application from Applications, test each page at normal display scaling.
2. Discover the printer, select it, try manual IP, add/update the queue, cancel administrator authorization and retry.
3. Print A4 color and gray PDFs, at least two pages, one and multiple copies. Verify page order, landscape, page ranges and application-specific print settings separately; collated copies and N-up are not certified by current physical tests.
4. Print each language's calibration PDF at 100%. Measure the square and four margins, save corrections, print again. Confirm positive X/Y directions, scales and persistence across restart/update.
5. Open status: compare levels with the printer web interface, refresh, disconnect/reconnect the printer, switch selected IP and pages. Confirm unavailable values and no stale readings.
6. Export diagnostic text and inspect it before sharing. Open printer/settings/sharing buttons. Check uninstall with an empty queue, and verify unrelated printers remain.

Other Apple Silicon chips, Intel, USB, AirPrint and future macOS releases have not been physically tested. Intel/USB/AirPrint are outside the release scope; the M-series ARM64 build target does not assert a test on every model.

## 1.1.0 additions

Language selection parsing and Italian/English UI strings are covered by core tests; `python3 tests/localization.py` checks translation coverage for every static UI localization key. Installer package choices select exactly one script-only language component; the selected language is stored in the root-owned driver directory and used at application launch. A Mac GUI installation is still required to verify the customization page and both language layouts: the local installer inspection tool could not locate the target volume in this execution environment. System print/security dialogs follow macOS's own language.

The AirPrint source prototype passed local IPP attribute queries and dry-run PDF/URF conversion without printing. It is not activated by the installer. See airprint/README.md for remaining physical iOS and service lifecycle work.
