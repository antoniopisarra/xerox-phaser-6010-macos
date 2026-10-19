#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Foreground development service. Stop with Ctrl-C; nothing is installed persistently.
set -euo pipefail
cd "$(dirname "$0")/.."
for tool in /usr/bin/ippeveprinter /usr/libexec/cups/command/ippeveps; do
 [[ -x "$tool" ]] || { echo "Missing macOS component: $tool" >&2; exit 1; }
done
args=()
if [[ ${1:-} == --dry-run ]]; then
 [[ $# == 2 && -d $2 ]] || { echo 'Usage: run-bridge.sh --dry-run output-directory' >&2; exit 1; }
 export PHASER_AIRPRINT_DRY_RUN_DIR=$(cd "$2" && pwd)
 args=(-r _phaser6010test -n localhost)
else
 [[ $# == 0 ]] || exit 1
 /usr/bin/lpstat -p Phaser6010 >/dev/null
 /usr/bin/grep -q 'Xerox Phaser 6010N Community' /etc/cups/ppd/Phaser6010.ppd
 args=(-r _print,_universal)
 echo 'Development AirPrint bridge: reachable clients may submit jobs. Keep the Mac awake; Ctrl-C stops sharing.' >&2
fi
spool=$(/usr/bin/mktemp -d "${TMPDIR:-/private/tmp}/phaser-airprint-spool.XXXXXXXX")
trap 'rm -rf "$spool"' EXIT
/usr/bin/ippeveprinter -p 8631 \
 -P packaging/Phaser6010.ppd \
 -c "$PWD/airprint/print-job.sh" -d "$spool" "${args[@]}" 'Xerox Phaser 6010N via Mac' &
server=$!
trap 'kill "$server" 2>/dev/null || true; wait "$server" 2>/dev/null || true; rm -rf "$spool"' EXIT
trap 'exit 0' INT TERM HUP
wait "$server"
