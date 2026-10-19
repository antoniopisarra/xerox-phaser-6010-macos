# AirPrint bridge

Version 1.2.0 installs the job helper and adds a graphical enable/disable control. Sharing is off by default. From 1.3.0 the utility manages an opt-in per-user LaunchAgent that survives closing the window and restarts at login. Physical printing from the owner's iPhone was confirmed after installing 1.2.1; iPad and other client/option combinations remain to be tested. The scripts below remain useful for developer dry runs.

The bridge uses a private build of Apple CUPS ippeveprinter (1.2.1+) with the Phaser PPD, advertises a separate `Xerox Phaser 6010N via Mac` endpoint and runs the system `ippeveps` converter for incoming PDF, JPEG, PWG Raster or Apple Raster/URF. The resulting PostScript is submitted to the existing `Phaser6010` CUPS queue. No proprietary library is added. This is based on the [CUPS IPP server](https://openprinting.github.io/cups/doc/man-ippeveprinter.html) and [converter](https://openprinting.github.io/cups/doc/man-ippevepcl.html) interfaces.

## Development use

On a trusted local network, with the normal driver installed and queue configured:

```sh
./airprint/run-bridge.sh
```

This starts a developer foreground service on TCP 8631 with Bonjour `_print,_universal` subtypes. Stop with Ctrl-C. No launch daemon, firewall rule or persistent sharing setting is installed. Keep the Mac awake. Reachable clients can submit print jobs without authentication: do not expose the port to the internet. Print job acceptance means submission to CUPS, not physical completion; check the local queue. Cancellation after local submission is not yet propagated between the two queues.

For a nonprinting development test, use an existing output directory:

```sh
mkdir -p build/airprint-output
./airprint/run-bridge.sh --dry-run "$PWD/build/airprint-output"
```

Dry-run mode saves converted PostScript and never calls `lp`. It uses the custom Bonjour subtype `_phaser6010test` rather than `_universal`; it still opens a local server port and may be reachable on the LAN. Test files are retained in the chosen directory for inspection; remove them after testing. The temporary server spool is removed on normal exit.

## Evidence so far

On the development Mac, Get-Printer-Attributes succeeded and reported A4/Letter, one-sided printing, color/monochrome, 600 dpi and Apple Raster support (`V1.4,CP1,RS600,W8,SRGB24`). A PDF and a synthetic sRGB Apple Raster job passed through IPP and completed conversion in dry-run mode. An empty raster job was rejected. These tests sent **no physical print job**.

`./tests/airprint.sh` repeats offline PDF/URF conversion and verifies the resulting PostScript with the private Ghostscript, without launching a network server. The macOS-supplied executable rejected actual iPhone Create-Job requests. The private server resolves the observed rejection; it also rejects some combinations of generic-model flags and PPD settings, so the prototype derives capabilities directly from the PPD rather than adding conflicting flags.

## Remaining acceptance and future work

- Discover and select the service from a real iPhone/iPad on the same LAN, then physically print PDF/photo, color/gray and multiple pages/copies.
- Verify paper sizes, scale, orientation and existing calibration after Apple Raster conversion.
- Verify actual advertised DNS-SD records, firewall behavior, sleep/wake, queue failures, client cancellation and privacy of job/status data.
- Persistent per-user hosting is implemented in 1.3.0; verify the actual GUI, close/reopen, display sleep, logout/login, update and removal on the owner's Mac.
- Decide authentication/TLS and local-network access policy; never silently enable sharing on installation.

Physical iPhone printing is confirmed on the owner's 1.2.1 installation. This is not a claim of Apple certification or testing of all iOS devices/options.
