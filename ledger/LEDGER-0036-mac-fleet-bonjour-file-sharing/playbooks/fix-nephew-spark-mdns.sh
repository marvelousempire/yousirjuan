#!/usr/bin/env bash
# Fix nephew-spark.local IPv4 mDNS on DGX + optional Mac /etc/hosts fallback.
set -euo pipefail

LEDGER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REMOTE_HOST="${NEPHEW_SPARK_SSH:-nephew-spark}"
SPARK_IP="${NEPHEW_SPARK_LAN_IP:-192.168.10.205}"

echo "==> Fix nephew-spark mDNS (remote)"
ssh "$REMOTE_HOST" bash -s <<REMOTE
set -euo pipefail
LAN_IF="\$(ip -4 route get 192.168.10.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if(\$i=="dev"){print \$(i+1); exit}}')"
echo "192.168.10.205	nephew-spark.local" | sudo tee /etc/avahi/hosts >/dev/null
sudo tee /etc/avahi/avahi-daemon.conf >/dev/null <<EOF
[server]
host-name=nephew-spark
domain-name=local
use-ipv4=yes
use-ipv6=no
allow-interfaces=\${LAN_IF:-enx6c6e072c96c6}
deny-interfaces=docker0,lo,br-*,veth*,wg0
publish-addresses=yes
publish-hinfo=no
publish-workstation=no
publish-aaaa-on-ipv4=no
EOF
sudo systemctl restart avahi-daemon smbd nmbd 2>/dev/null || sudo systemctl restart avahi-daemon
sleep 2
avahi-resolve -4 -n nephew-spark.local || true
REMOTE

HOSTS_LINE="${SPARK_IP} nephew-spark nephew-spark.local"
if grep -qF "nephew-spark.local" /etc/hosts 2>/dev/null; then
  echo "○ /etc/hosts already has nephew-spark"
else
  osascript -e "do shell script \"grep -qF 'nephew-spark.local' /etc/hosts || echo '${HOSTS_LINE}' >> /etc/hosts\" with administrator privileges" \
    && echo "✓ added /etc/hosts fallback" || echo "! add manually: ${HOSTS_LINE}"
fi
echo "✓ nephew-spark mDNS repair done (ledger: ${LEDGER})"