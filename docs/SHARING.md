# AirPrint sharing through the Mac

Version 1.2.0 adds an explicit AirPrint page in the Italian/English utility. First configure the normal Phaser6010 queue, then choose Enable AirPrint. The service appears as **Xerox Phaser 6010N via Mac**. On iPhone/iPad, connected to the same LAN, choose Share → Print → Select Printer.

The app runs Apple's installed ippeveprinter on TCP 8631, advertises Bonjour `_print,_universal`, and derives capabilities from the Phaser PPD. The system ippeveps converter accepts PDF/JPEG/PWG Raster/Apple Raster and produces PostScript, which the installed helper submits to the existing CUPS queue. The established driver and saved calibration are reused. Only A4/Letter and single-sided printing are advertised. The helper explicitly forwards paper size to the local queue.

Sharing is off at installation and app launch. Enable starts a child process and checks its IPP endpoint before displaying active status. Disable or quitting the app terminates that child. No launch daemon, login item, system CUPS sharing change or firewall rule is installed. Keep the app open and the Mac on. The app runs caffeinate to inhibit idle system sleep while active; manual sleep/lid closure still interrupts availability. If macOS asks about local network or incoming connections, allow them for the service on a trusted LAN.

Reachable clients can submit jobs without authentication. Do not expose TCP 8631 to the internet. Server logs are discarded because they may contain job titles/client addresses. Temporary spool data is private to the current user and removed on normal service exit. A crash/power failure can leave temporary data for later OS cleanup. Stopping sharing does not cancel work already forwarded to the local CUPS queue; use Printers & Scanners to manage those jobs.

The current implementation hosts through the signed-by-Apple system tools; it is not an Apple certification claim. Local IPP discovery/capability queries, PDF/URF conversion and app-controller lifecycle tests are separate from physical iPhone/iPad acceptance. The latter remains pending on the owner's LAN. If the printer does not appear, check same-network Wi-Fi, guest/client isolation, local-network permissions, firewall and whether another process already uses port 8631.

The old Mac sharing button remains available for standard macOS Printer Sharing, independently of this bridge. Additional design and development instructions are in [airprint/README.md](../airprint/README.md).
