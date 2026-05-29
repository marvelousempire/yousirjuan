#!/bin/sh
# glmt6000-firewall-persist.sh — write the WG forwarding rules to /etc/firewall.user
# on the GL-MT6000 (OpenWRT). Idempotent: re-runs are a no-op if rules already present.
#
# Run on the GL-MT6000 itself:
#   ssh root@192.168.8.1
#   sh glmt6000-firewall-persist.sh

set -e

F=/etc/firewall.user
RULE1="iptables -I FORWARD 1 -i wg0 -d 192.168.8.0/24 -j ACCEPT"
RULE2="iptables -I FORWARD 1 -i br-lan -s 192.168.8.0/24 -d 10.0.0.0/24 -j ACCEPT"

touch "$F"

grep -qF "$RULE1" "$F" || echo "$RULE1" >> "$F"
grep -qF "$RULE2" "$F" || echo "$RULE2" >> "$F"

chmod +x "$F"

echo "=== /etc/firewall.user ==="
cat "$F"
echo
echo "=== applying now ==="
/etc/init.d/firewall restart 2>&1 | tail -3
echo
echo "=== verifying ==="
iptables -L FORWARD -v -n --line-numbers | head -6
