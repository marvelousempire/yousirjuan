# 02 — Fix nephew-spark.local mDNS on the DGX (Docker pollution)

## Symptom

From fivemac:

```bash
ping nephew-spark.local   # Unknown host, or wrong subnet
dscacheutil -q host -a name nephew-spark.local   # IPv6 only, or wrong IP
```

From nephew-spark:

```bash
avahi-resolve -4 -n nephew-spark.local
# BAD: 192.168.128.1 (docker bridge)
# GOOD: 192.168.10.205 (house LAN)
```

## Cause

DGX runs many Docker bridges (`br-*`) and `veth*` interfaces. Default avahi publishes the host on **all** interfaces — Macs get garbage A records.

## Fix (on nephew-spark)

```bash
ssh nephew-spark

# Static host entry
echo '192.168.10.205	nephew-spark.local' | sudo tee /etc/avahi/hosts

# Restrict interfaces (LAN NIC name may differ — check: ip -4 route get 192.168.10.1)
sudo tee /etc/avahi/avahi-daemon.conf <<'EOF'
[server]
host-name=nephew-spark
domain-name=local
use-ipv4=yes
use-ipv6=no
allow-interfaces=enx6c6e072c96c6
deny-interfaces=docker0,lo,br-*,veth*,wg0
publish-addresses=yes
publish-hinfo=no
publish-workstation=no
publish-aaaa-on-ipv4=no
EOF

sudo systemctl restart avahi-daemon smbd nmbd
avahi-resolve -4 -n nephew-spark.local   # must print 192.168.10.205
```

Or from fivemac:

```bash
bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/fix-nephew-spark-mdns.sh
```

## Optional Mac fallback

If mDNS is slow after reboot, add to **fivemac** `/etc/hosts`:

```
192.168.10.205 nephew-spark nephew-spark.local
```

This does not fix Finder labels — you still must mount via hostname URLs. It only helps resolution.

## Verify from fivemac

```bash
dns-sd -G v4 nephew-spark.local
ping -c1 nephew-spark.local
```