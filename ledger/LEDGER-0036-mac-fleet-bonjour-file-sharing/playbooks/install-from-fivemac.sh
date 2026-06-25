#!/usr/bin/env bash
# Orchestrate LEDGER-0036 from fivemac.
set -euo pipefail

LEDGER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PB="$LEDGER/playbooks"

echo "==> LEDGER-0036 install from fivemac"

bash "$PB/fix-nephew-spark-mdns.sh"
osascript -e "do shell script \"MAC_ADMIN_USER=averygoodman bash '${PB}/configure-mac-admin-file-sharing.sh'\" with administrator privileges"
osascript -e "do shell script \"MAC_BONJOUR_NAME=fivemac bash '${PB}/configure-mac-bonjour-name.sh'\" with administrator privileges"
bash "$PB/ensure-nephew-spark-mounts.sh"
bash "$PB/ensure-mac-fleet-mounts.sh" || true
bash "$PB/install-launchagents.sh"
bash "$PB/drop-bootstrap-to-fleet.sh" || true

for host in averygoodman@192.168.10.159 averygoodman@192.168.10.166; do
  label="${host##*@}"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" 'true' 2>/dev/null; then
    echo "==> configuring ${label} remotely"
    ssh "$host" "MAC_ADMIN_USER=averygoodman bash -s" < "$PB/configure-mac-admin-file-sharing.sh" || true
    ssh "$host" "bash -s" < "$PB/configure-mac-bonjour-name.sh" || true
  else
    echo "! ${label}: run bootstrap-mac-fleet-ssh.sh on that Mac"
  fi
done

echo "✓ LEDGER-0036 playbooks complete — see journal.md for verification"