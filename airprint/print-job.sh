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
# Validate job options before the potentially expensive conversion.
requested_copies=${IPP_COPIES:-1}
[[ $requested_copies =~ ^[0-9]{1,3}$ ]] || { echo 'ERROR: Invalid copies.' >&2; exit 1; }
requested_copies=$((10#$requested_copies))
((requested_copies >= 1 && requested_copies <= 999)) || exit 1
paper=A4
case ${IPP_MEDIA:-${IPP_MEDIA_DEFAULT:-iso_a4_210x297mm}} in
 iso_a4_210x297mm|A4) paper=A4;; na_letter_8.5x11in|Letter) paper=Letter;;
 *) echo 'ERROR: Unsupported paper size.' >&2; exit 1;;
esac
if [[ -n ${IPP_MEDIA_COL:-} ]]; then
 collection=$IPP_MEDIA_COL
 if [[ $collection =~ media-size-name=na_letter_8[.]5x11in([\ }]|$) ]] || \
    { [[ $collection =~ x-dimension=21590([\ }]|$) ]] && [[ $collection =~ y-dimension=27940([\ }]|$) ]]; }; then
  selected=Letter
 elif [[ $collection =~ media-size-name=iso_a4_210x297mm([\ }]|$) ]] || \
      { [[ $collection =~ x-dimension=21000([\ }]|$) ]] && [[ $collection =~ y-dimension=29700([\ }]|$) ]]; }; then
  selected=A4
 else echo 'ERROR: Unsupported media collection.' >&2; exit 1
 fi
 if [[ -n ${IPP_MEDIA:-} && $paper != "$selected" ]]; then echo 'ERROR: Conflicting paper sizes.' >&2; exit 1; fi
 paper=$selected
fi
color=CMYK
case ${IPP_PRINT_COLOR_MODE:-auto} in
 monochrome) color=Gray;; auto|color) ;; *) echo 'ERROR: Unsupported color mode.' >&2; exit 1;;
esac
queue_copies=1
case $CONTENT_TYPE in image/urf|image/pwg-raster) queue_copies=$requested_copies;; esac
tmp=$(/usr/bin/mktemp -d "${TMPDIR:-/private/tmp}/phaser-airprint-job.XXXXXXXX")
trap 'rm -rf "$tmp"' EXIT
# A complete raster is required: the system converter can otherwise accept a truncated page.
case $CONTENT_TYPE in image/urf|image/pwg-raster)
 root=$(cd "$(dirname "$0")/.." && pwd)
 checker="$root/bin/phaser-check-raster"
 [[ -x "$checker" ]] || checker="$root/build/bin/phaser-check-raster"
 [[ -x "$checker" ]] || { echo 'ERROR: Raster checker missing; reinstall the driver.' >&2; exit 1; }
 if [[ $# == 0 ]]; then /bin/cat > "$tmp/input"; set -- "$tmp/input"; fi
 "$checker" "$1"
;; esac
# PDF/JPEG/PS conversion expands copies; the raster converter ignores IPP_COPIES.
# Forward raster copies to the queue instead of silently dropping them.
/usr/libexec/cups/command/ippeveps "$@" > "$tmp/job.ps"
[[ -s "$tmp/job.ps" ]] || { echo 'ERROR: Empty converted document.' >&2; exit 1; }
if [[ -n ${PHASER_AIRPRINT_DRY_RUN_DIR:-} ]]; then
 # Explicit development mode: save for inspection and NEVER contact the printer.
 [[ -d "$PHASER_AIRPRINT_DRY_RUN_DIR" ]] || exit 1
 target=$(/usr/bin/mktemp "$PHASER_AIRPRINT_DRY_RUN_DIR/job.XXXXXXXX")
 /bin/cp "$tmp/job.ps" "$target"
 /usr/bin/printf 'PageSize=%s\nCopies=%s\nColorModel=%s\n' "$paper" "$queue_copies" "$color" > "$target.options"
 echo 'INFO: Dry run saved; no print job submitted.' >&2
else
 /usr/bin/lp -d Phaser6010 -n "$queue_copies" -t 'AirPrint document' -o "PageSize=$paper" -o "ColorModel=$color" -o document-format=application/postscript "$tmp/job.ps" >/dev/null
 echo 'INFO: Submitted to the local Phaser6010 queue; check that queue for completion.' >&2
fi
