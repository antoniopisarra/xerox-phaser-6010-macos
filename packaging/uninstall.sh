#!/bin/bash
set -euo pipefail
[[ $(/usr/bin/id -u) == 0 ]] || exit 1
# Fixed paths only. Refuse to remove a queue that now points to another driver.
if [[ -f /etc/cups/ppd/Phaser6010.ppd ]]; then
 /usr/bin/grep -q 'Xerox Phaser 6010N Community' /etc/cups/ppd/Phaser6010.ppd || { echo 'La coda Phaser6010 appartiene a un altro driver.' >&2; exit 1; }
 /usr/sbin/lpadmin -x Phaser6010
fi
/bin/rm -rf /Library/Printers/Phaser6010 '/Applications/Configura Xerox Phaser 6010N.app'
/usr/sbin/pkgutil --forget org.community.phaser6010 >/dev/null

/usr/sbin/pkgutil --forget org.community.phaser6010.language.italian >/dev/null 2>&1 || true
/usr/sbin/pkgutil --forget org.community.phaser6010.language.english >/dev/null 2>&1 || true
