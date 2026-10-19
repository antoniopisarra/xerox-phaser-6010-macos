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

GUI automation was unavailable during development. On 19 October 2026 the owner supplied three real screenshots after installing 1.1.0: the English Printer, Status and toner, and Calibration pages. The captures show discovery of a compatible printer, Ready status, refreshed toner values and the calibration controls. They are preserved in docs/screenshots and linked from both READMEs. Italian layout and individual button/printing workflows still need separate acceptance; screenshots do not establish these behaviors. Compilation and core tests cannot replace these checks:

1. Install the downloaded package on a clean ARM64 Mac; observe actual Gatekeeper behavior. Open the application from Applications, test each page at normal display scaling.
2. Discover the printer, select it, try manual IP, add/update the queue, cancel administrator authorization and retry.
3. Print A4 color and gray PDFs, at least two pages, one and multiple copies. Verify page order, landscape, page ranges and application-specific print settings separately; collated copies and N-up are not certified by current physical tests.
4. Print each language's calibration PDF at 100%. Measure the square and four margins, save corrections, print again. Confirm positive X/Y directions, scales and persistence across restart/update.
5. Open status: compare levels with the printer web interface, refresh, disconnect/reconnect the printer, switch selected IP and pages. Confirm unavailable values and no stale readings.
6. Export diagnostic text and inspect it before sharing. Open printer/settings/sharing buttons. Check uninstall with an empty queue, and verify unrelated printers remain.

Other Apple Silicon chips, Intel, USB, AirPrint and future macOS releases have not been physically tested. Intel/USB/AirPrint are outside the release scope; the M-series ARM64 build target does not assert a test on every model.

## 1.1.0 additions

Language selection parsing and Italian/English UI strings are covered by core tests; `python3 tests/localization.py` checks translation coverage for every static UI localization key. Installer package choices select exactly one script-only language component; the selected language is stored in the root-owned driver directory and used at application launch. The owner's post-installation screenshots confirm the English layouts of all three pages. The installer customization page and Italian layout are not covered by those captures; the local installer inspection tool could not locate the target volume in this execution environment. System print/security dialogs follow macOS's own language.

The AirPrint source prototype passed local IPP attribute queries and dry-run PDF/URF conversion without printing. It is not activated by the installer. See airprint/README.md for remaining physical iOS and service lifecycle work.

## 1.2.0 AirPrint acceptance

The GUI controller is tested directly by `./tests/bridge.sh`, using a private fixture runtime and dry-run helper: IPP startup/readiness, PDF conversion, stop and restart, without contacting a physical printer. `./tests/airprint.sh` checks PDF/Apple Raster PostScript output offline. Physical iOS discovery, actual print/calibration, copies/media/orientation, firewall permission prompts and the new GUI page remain for the owner to test. No automated test certifies physical AirPrint behavior.

## 1.2.1 negotiation regression

The owner reproduced an iPhone Waiting/Printing loop against the macOS executable. Read-only job history showed no accepted jobs. Standard A4 media-col validation failed because rounded PPD dimensions exported 20990 × 29704 rather than 21000 × 29700; corrected dimensions now pass tests/airprint-validate-a4.test. A temporary private IPP server then accepted the owner's iPhone Create-Job/Send-Document and completed conversion; the owner confirmed the iPhone queue cleared. This diagnostic mode did not forward the document to the printer. The final private server build also passes A4 validation, chunked create/send, controller stop/restart and PDF/URF conversion checks. The owner subsequently uninstalled the older package, installed 1.2.1 and confirmed that physical printing from the iPhone worked perfectly. This verifies that reported scenario on the owner's setup; it does not establish every iOS version, paper/copy combination or Mac client.
