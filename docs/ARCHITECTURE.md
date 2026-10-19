# Architecture

The native AppKit utility configures a fixed CUPS queue, `Phaser6010`, pointing to `socket://IPv4:9100` and the installed PPD. It requests administrator authorization through macOS only for privileged changes. IPv4 addresses and calibration numbers are validated before use. The application does not bundle proprietary printer software.

The legacy CUPS chain is PDF/PostScript → dedicated Bash filter → private Ghostscript → PAM CMYK or PGM gray, 600 dpi → foo2hbpl1 → CUPS socket backend → printer. The filter checks supported paper/color/copy options, stages output before sending it downstream and fails without partial HBPL output when conversion fails. Device-specific protocol encoding remains in the established encoder. The encoder patch bounds page-tail lookahead; the original source remains available for comparison.

Private runtime: `/Library/Printers/Phaser6010/{bin,filter,gs}`. The PPD and uninstall helper are at that root. Fonts and profiles are private to Ghostscript. System printing binaries are used, not replaced.

`calibration.conf` stores horizontal/vertical millimeters and independent scale percentages. Writes are validated and atomically replaced with administrator authorization. An older horizontal-offset-mm setting is read for migration. New packages contain neither file, preserving existing calibration. Ghostscript applies offsets and centered scale in BeginPage without forced fit-to-page. Positive user Y is converted to the opposite Ghostscript PageOffset sign.

Discovery combines Bonjour service browsing with a bounded SNMP v1 local-network probe for a matching Xerox/Phaser 6010 identity. Toner status uses read-only Printer MIB/Host Resources MIB requests through macOS snmpget. Identity/status and supplies are requested separately to avoid the printer's SNMP tooBig limit. Toner percentages use level/max; negative/unknown values never become fake percentages. Toner polling runs only while the status page is visible. The separate opt-in AirPrint service is described below.

Diagnostic export contains version, OS, driver availability, calibration and the current state/toner snapshot. It intentionally excludes documents, job titles, usernames, printer IP and serial number. It does not dump the full CUPS error log.

CUPS PPD/filter support is legacy and may change in future macOS. Version 1.3.0 uses an opt-in per-user LaunchAgent to run the private Apple CUPS IPP server independently of the configuration app. Its tracked policy patch disables URI fetching and HTML job pages, redacts job metadata and removes sample supplies. The system ippeveps converter forwards through the existing driver. A bounded native raster preflight rejects truncated URF/PWG input before conversion. The service holds an idle-system-sleep assertion while allowing display sleep. It requires a logged-in user; it is not a pre-login daemon. See SHARING.md for lifecycle and acceptance limits.

References: [Printer MIB](https://www.rfc-editor.org/rfc/rfc3805.html), [Host Resources MIB](https://www.rfc-editor.org/rfc/rfc2790.html), [Ghostscript](https://ghostscript.com/), [upstream foo2zjs](http://foo2zjs.rkkda.com/).
