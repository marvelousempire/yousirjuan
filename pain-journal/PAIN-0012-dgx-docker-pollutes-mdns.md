# PAIN-0012 — Docker on DGX pollutes nephew-spark.local mDNS

**Surfaced during:** [LEDGER-0036 Mac fleet Bonjour file sharing](../ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/journal.md) (2026-06-25)

## Problem

`nephew-spark.local` fails to resolve from fivemac, or resolves to wrong address (`192.168.128.1` docker bridge). Finder **connection failed**. Emergency workaround used raw IPs everywhere.

## Root cause

`avahi-daemon` on nephew-spark published host records on Docker `br-*` and `veth*` interfaces. Mac mDNS got garbage A records.

## Resolution

- Restrict avahi: `allow-interfaces=<LAN NIC>`, `deny-interfaces=docker0,lo,br-*,veth*,wg0`
- Static `/etc/avahi/hosts`: `192.168.10.205 nephew-spark.local`
- Playbook: `fix-nephew-spark-mdns.sh`
- Runbook: [02-nephew-spark-mdns-docker-fix.md](../ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/runbooks/02-nephew-spark-mdns-docker-fix.md)

## Status

✅ Resolved — `avahi-resolve -4 -n nephew-spark.local` returns `192.168.10.205` on DGX; fivemac `dns-sd -G v4` matches.

## Feature follow-up

🔜 Document in `hardware/dgx-spark-frontier-node.md` as standard post-Docker avahi hardening for any AI-island host.