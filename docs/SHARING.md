# AirPrint sharing through the Mac

Version 1.2.0 adds an explicit AirPrint page in the Italian/English utility. First configure the normal Phaser6010 queue, then choose Enable AirPrint. The service appears as **Xerox Phaser 6010N via Mac**. On iPhone/iPad, connected to the same LAN, choose Share → Print → Select Printer.

From 1.2.1 the app runs a private IPP server compiled from pinned Apple CUPS source on TCP 8631, advertises Bonjour `_print,_universal`, and derives capabilities from the Phaser PPD. The system ippeveps converter accepts PDF/JPEG/PWG Raster/Apple Raster and produces PostScript, which the installed helper submits to the existing CUPS queue. The established driver and saved calibration are reused. Only A4/Letter and single-sided printing are advertised. The helper explicitly forwards paper size to the local queue.

Sharing is off at installation. In 1.3.0, Enable writes a private per-user LaunchAgent and starts it in the logged-in GUI session. The agent owns the IPP server independently of the utility window, restarts it on failure and at subsequent user logins, and uses a fresh private spool for every server run. Closing the app leaves sharing active. Disable unloads the agent, removes its login registration and clears its spool. Uninstall through the app disables the agent first; removal is refused if that step fails.

The agent runs caffeinate with **-i only**. It prevents idle system sleep while enabled and allows the display to switch off; it does not force the screen on or rewrite power settings. Manual system sleep, laptop lid closure, logout and shutdown interrupt availability. A user must log in after a reboot: this is a per-user agent, not a pre-login system daemon. Do not enable a second sharing host in another user session on the same port.

Reachable clients can submit jobs without authentication. Do not expose TCP 8631 to the internet. Server logs are discarded because they may contain job titles/client addresses. The bridge policy disables server-side file/URL fetching and HTML job pages, redacts job names/users in IPP history, and omits sample supply values. The utility retains real SNMP toner readings. Temporary spool data is private to the current user and removed on normal server exit. A crash/power failure can leave temporary data for later OS cleanup. Stopping sharing does not cancel work already forwarded to the local CUPS queue; use Printers & Scanners to manage those jobs.

The private IPP executable has an ad hoc integrity signature; it is not an Apple certification claim. The macOS converter and libraries are used without modification. Local IPP discovery/capability queries, PDF/URF conversion and app-controller lifecycle tests are separate from physical iPhone/iPad acceptance. The owner confirmed successful physical printing from the iPhone after removing the older package and installing 1.2.1. Other client/option combinations remain to be tested. If the printer does not appear, check same-network Wi-Fi, guest/client isolation, local-network permissions, firewall and whether another process already uses port 8631.

The old Mac sharing button remains available for standard macOS Printer Sharing, independently of this bridge. Additional design and development instructions are in [airprint/README.md](../airprint/README.md).


## 1.3.0 physical acceptance update — 19 October 2026

The owner confirmed that the iPhone discovers the printer and physically prints while the Mac is locked (lock screen, with the user still logged in). Closing the MacBook lid interrupted sharing in the tested setup. Locking the screen is distinct from logging out or suspending the system. This report does not separately confirm operation with the setup app fully quit, restart after login, display-off duration or new paper/copy combinations. The supplied 1.3.0 screenshot shows AirPrint enabled and is preserved in docs/screenshots/airprint.png.
