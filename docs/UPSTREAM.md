# Upstream provenance and attribution

Project: [OpenPrinting/foo2zjs](https://github.com/OpenPrinting/foo2zjs). The supplied Makefile identifies this URL as URLHBPL1; the supplied ChangeLog references OpenPrinting's first release and HBPLv1 issue #2. Historical project website: http://foo2zjs.rkkda.com/.

The source input for this port was the user-supplied `foo2zjs-macos.zip`, rather than a Git checkout with verifiable remote/commit metadata. Its ChangeLog records an HBPLv1 merge by Joe Da Silva dated 2026-08-25, based on Dave Coffin's 2014 patch. Do not assume that this supplied encoder exactly matches the current default branch of OpenPrinting/foo2zjs.

The unmodified supplied encoder is retained in `vendor/original-encoder/foo2hbpl1.c`, SHA-256:

```
97a6d13225e6fe3f7531cdfebe7d56e3f1490f309e6bec3b8e2bdce8a023740f
```

Its header credits Robert Szalai, Rick Richardson, Dave Coffin and Joe Da Silva and grants GPL-2.0-or-later. These notices are preserved. Compare the reference file with `src/foo2hbpl1.c` to inspect this port's bounds/allocation fixes. The AppKit utility, dedicated CUPS filter, calibration resources, build scripts and installer are the macOS integration developed for this project.

Ghostscript/GhostPDL is a separate upstream dependency from [Artifex](https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/tag/gs10080), distributed under AGPL-3.0-or-later with component notices. Its complete pinned source and build recipe accompany the binary distribution.

## Private AirPrint IPP server

Apple CUPS commit `a8968fc4257322b1e4e191c4bccedea98d7b053e`: https://github.com/apple/cups/tree/a8968fc4257322b1e4e191c4bccedea98d7b053e. Only the tools/ippeveprinter.c with the tracked bridge policy patch application is compiled against the native macOS libcups. Apache-2.0 and upstream exceptions/notices are retained in vendor/LICENSE-CUPS and vendor/NOTICE-CUPS. Full archive cups-a8968fc.tar.gz (SHA-256 `72cc272eb95dac3b8f5914ce727e9ee454a2aa10a56ca954cfc66899eb236624`) is included in binary/source distributions. No existing Apple executable is copied or modified.

Version 1.3.0 applies packaging/ipp-server.patch: URI fetch operations and sample HTML job pages are disabled; IPP history redacts user-provided names; sample consumable levels are omitted. Upstream source archives and notices remain unchanged and the patch/build recipe are included.
