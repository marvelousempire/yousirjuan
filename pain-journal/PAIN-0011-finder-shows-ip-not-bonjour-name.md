# PAIN-0011 — Finder Network shows IP addresses instead of fleet hostnames

**Surfaced during:** [LEDGER-0036 Mac fleet Bonjour file sharing](../ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/journal.md) (2026-06-25)

## Problem

Operator sees **192.168.10.159** and **192.168.10.166** in Finder → Network **with eject arrows**, while **MacBook Pro** and **NASA** show friendly names. Feels broken — "I want the nice names like they're supposed to."

## Root cause

Not a Bonjour failure alone. **Mounted SMB volumes** display the host from the mount URL. Connecting via `smb://192.168.10.159/...` creates an IP-labelled row; the same Mac also browses as **MacBook Pro**.

## Resolution

- Eject IP mounts; reconnect via `onemac.local`, `twomac.local`, `nephew-spark.local`
- Playbooks: `ensure-nephew-spark-mounts.sh`, `ensure-mac-fleet-mounts.sh`
- Runbook: [01-why-ips-show-in-finder.md](../ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/runbooks/01-why-ips-show-in-finder.md)

## Status

✅ Resolved on fivemac for nephew-spark and twomac. onemac SeverD pending operator reconnect by hostname.