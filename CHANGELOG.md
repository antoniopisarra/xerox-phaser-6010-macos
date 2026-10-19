# Changelog

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
