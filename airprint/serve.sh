#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# launchd owns this foreground runner; each restart gets a fresh private spool.
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077
[[ $# == 1 && -d $1 ]] || exit 1
root=$(cd "$(dirname "$0")/.." && pwd)
spool=$(/usr/bin/mktemp -d "$1/session.XXXXXXXX")
server=''
cleanup() {
 if [[ -n "$server" ]]; then kill "$server" 2>/dev/null || true; wait "$server" 2>/dev/null || true; fi
 /bin/rm -rf "$spool"
}
trap cleanup EXIT
trap 'exit 0' INT TERM HUP
"$root/bin/phaser-ipp-server" -p 8631 -P "$root/Phaser6010.ppd" \
 -c "$root/airprint/print-job.sh" -d "$spool" -r _print,_universal 'Xerox Phaser 6010N via Mac' &
server=$!
wait "$server"
