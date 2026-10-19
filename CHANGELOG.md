# Changelog

## 1.3.0

- AirPrint now runs through an opt-in per-user LaunchAgent: survives closing the utility and restarts at login; Disable removes the agent. Prevents idle system sleep while allowing display sleep.
- Disabled server-side Print-URI/Send-URI, sample HTML job pages and fictitious supplies; redacted job titles/users in IPP responses.
- Excluded Mac AirPrint bridges from direct-hardware discovery; invalidated stale discovery callbacks on stop.
- Bounded command output during reading and force-stopped commands that ignore the timeout.
- Rejected malformed, oversized and truncated encoder raster input; validated complete Apple/PWG Raster before conversion.
- Fixed raster copy forwarding, media collections independent of key order, name-only paper selection and monochrome queue options.
- Cached the installed interface language and cleared stale toner data for invalid selections.
- Added targeted regressions and detailed review/benchmark results. Background registration and new physical print paths require Mac acceptance; local tests send no jobs to the Xerox.

## 1.2.1

- Fixed A4 IPP negotiation: PPD dimensions now map exactly to 21000 × 29700 hundredths of a millimeter instead of rounded point dimensions rejected by standard media-col requests.
- Replaced the system ippeveprinter executable with a private build from pinned Apple CUPS source. The macOS-supplied executable rejected the owner's iPhone Create-Job requests with “Unexpected document data following request”.
- The private server accepted iPhone Create-Job/Send-Document and completed conversion in nonprinting diagnostics; the owner subsequently confirmed successful physical iPhone printing after installing 1.2.1.
- Added standard A4 Validate-Job and chunked Create-Job/Send-Document regression checks. Bundled complete CUPS source and Apache license/notices.

## 1.2.0

- Added Italian/English AirPrint page with explicit enable/disable, startup IPP check and error/status feedback.
- Reuses Apple's system IPP server and Apple Raster/PostScript converter with the existing calibrated CUPS queue; forwards A4/Letter media.
- Sharing stays off by default and stops on app exit; inhibits idle Mac sleep while active, without installing a persistent daemon.
- Added controller lifecycle and nonprinting conversion tests. Physical iPhone/iPad acceptance is still pending.

## 1.1.0

- Italian/English utility interface, selected during installation; applies to every user of the Mac.
- Translated pages, menus, status messages, validation errors and accessibility printer labels.
- Calibration PDF defaults to the selected interface language; its separate language selector remains available.
- Corrected the vertical direction hint to match the implemented positive-down calibration.
- Initial AirPrint bridge research/prototype is documented separately; no automatic network sharing is enabled.

## 1.0.0

- Native ARM64 installer and AppKit setup utility for Ethernet Xerox Phaser 6010N, macOS 26+.
- Dedicated CUPS/Ghostscript/HBPLv1 pipeline without Foomatic or an end-user Homebrew dependency.
- Encoder page-tail bounds fix; sandbox-compatible option parsing; removal of forced PDF scaling.
- Network discovery/manual IP, queue setup, printer status and four toner levels.
- Per-install X/Y offsets and independent scale calibration, measured-value calculator, bilingual calibration PDFs and print button.
- Application icon, printer/settings/sharing links, reduced diagnostic export and uninstall workflow.
- Non-relocatable installer bundle; updates preserve local calibration.
- Complete corresponding source, dependency checksum and third-party licenses; Italian/English documentation.

Earlier 0.1–0.3 development packages were local iterations used to diagnose installation, printing and calibration. The release package remains unsigned with Developer ID and unnotarized. See docs/TESTING.md for verified behavior and remaining checks.
