#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Development bridge: IPP/Apple Raster -> PostScript -> existing local CUPS queue.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077
[[ $# -le 1 ]] || exit 1
case ${CONTENT_TYPE:-} in
 application/pdf|application/postscript|image/jpeg|image/pwg-raster|image/urf) ;;
 *) echo 'ERROR: Unsupported document format.' >&2; exit 1;;
esac
case ${IPP_SIDES:-one-sided} in one-sided) ;; *) echo 'ERROR: Duplex is not supported.' >&2; exit 1;; esac
tmp=$(/usr/bin/mktemp -d "${TMPDIR:-/private/tmp}/phaser-airprint-job.XXXXXXXX")
trap 'rm -rf "$tmp"' EXIT
# The system converter handles requested copies and raster formats; submit one PS job.
/usr/libexec/cups/command/ippeveps "$@" > "$tmp/job.ps"
[[ -s "$tmp/job.ps" ]] || { echo 'ERROR: Empty converted document.' >&2; exit 1; }
if [[ -n ${PHASER_AIRPRINT_DRY_RUN_DIR:-} ]]; then
 # Explicit development mode: save for inspection and NEVER contact the printer.
 [[ -d "$PHASER_AIRPRINT_DRY_RUN_DIR" ]] || exit 1
 target=$(/usr/bin/mktemp "$PHASER_AIRPRINT_DRY_RUN_DIR/job.XXXXXXXX")
 /bin/cp "$tmp/job.ps" "$target"
 echo 'INFO: Dry run saved; no print job submitted.' >&2
else
 /usr/bin/lp -d Phaser6010 -n 1 -t 'AirPrint document' -o document-format=application/postscript "$tmp/job.ps" >/dev/null
 echo 'INFO: Submitted to the local Phaser6010 queue; check that queue for completion.' >&2
fi
