---
ledgerId: LEDGER-0036
title: Mac fleet Bonjour file sharing — nephew-spark SMB + admin-only LAN mounts
status: shipped
opened: 2026-06-25
closed: 2026-06-25
related-pains:
  - PAIN-0011
  - PAIN-0012
related-tickets:
  - clinic/cases/0080-printer-airprint-onemac-reshare-auth
triggers:
  - "connect to nephew-spark from fivemac"
  - "Finder Network shows IP addresses not hostnames"
  - "Mac file sharing admin only"
---

# LEDGER-0036 — Mac fleet Bonjour file sharing

## Ask

Wire **fivemac**, **onemac**, **twomac**, and **nephew-spark** (DGX) so files appear in Finder like normal Mac-to-Mac sharing — **nice Bonjour names**, not raw LAN IPs. Admin-only access. Fix **connection failed** when `nephew-spark.local` did not resolve.

## Outcome

**Shipped on fivemac + nephew-spark.** Root cause was twofold: (1) Docker on the DGX polluted mDNS so `nephew-spark.local` advertised docker bridge IPs; (2) SMB mounts used `192.168.10.x` URLs, so Finder Network listed IPs beside Bonjour names. Fixed avahi on DGX, remounted via hostnames, locked fivemac File Sharing to admin home only. **onemac/twomac** still need one-time bootstrap on each machine (no SSH key from fivemac yet).

## Fleet map (GL-MT6000 `192.168.10.0/24`)

| Tag | LAN IP | Bonjour | SMB browse name | Admin user |
|-----|--------|---------|-----------------|------------|
| **fivemac** | 192.168.10.184 | `fivemac.local` | fivemac | averygoodman |
| **onemac** | 192.168.10.159 | `onemac.local` | MacBook Pro | averygoodman |
| **twomac** | 192.168.10.166 | `twomac.local` | _(not advertising SMB yet)_ | averygoodman |
| **nephew-spark** | 192.168.10.205 | `nephew-spark.local` | nephew-spark | abrownsanta |
| **bigmac** | 192.168.10.182 | `bigmac.lan` | AVERY's iMac | — |
| **NASA** | 192.168.10.119 | `nasa.local` | NASA | abrownsanta |

## Runbooks

- [01-why-ips-show-in-finder.md](runbooks/01-why-ips-show-in-finder.md) — duplicate IP + name entries in Network
- [02-nephew-spark-mdns-docker-fix.md](runbooks/02-nephew-spark-mdns-docker-fix.md) — avahi allow/deny + static hosts on DGX
- [03-admin-only-mac-file-sharing.md](runbooks/03-admin-only-mac-file-sharing.md) — guest off, home folder only
- [04-mount-via-bonjour-names.md](runbooks/04-mount-via-bonjour-names.md) — Connect to Server + auto-mount LaunchAgents
- [05-fleet-mac-bootstrap-onemac-twomac.md](runbooks/05-fleet-mac-bootstrap-onemac-twomac.md) — SSH trust + sharing on peer Macs
- [06-nephew-spark-smb-sftp.md](runbooks/06-nephew-spark-smb-sftp.md) — DGX shares: Developer, home, SFTP

## Playbooks

| Script | Purpose |
|--------|---------|
| [fix-nephew-spark-mdns.sh](playbooks/fix-nephew-spark-mdns.sh) | Repair DGX avahi + optional Mac `/etc/hosts` fallback |
| [configure-mac-admin-file-sharing.sh](playbooks/configure-mac-admin-file-sharing.sh) | Admin-only SMB on any Mac |
| [configure-mac-bonjour-name.sh](playbooks/configure-mac-bonjour-name.sh) | Align ComputerName with LocalHostName |
| [ensure-nephew-spark-mounts.sh](playbooks/ensure-nephew-spark-mounts.sh) | Mount DGX via `nephew-spark.local` |
| [ensure-mac-fleet-mounts.sh](playbooks/ensure-mac-fleet-mounts.sh) | Mount onemac/twomac shares by hostname |
| [bootstrap-mac-fleet-ssh.sh](playbooks/bootstrap-mac-fleet-ssh.sh) | Run **on** onemac/twomac once |
| [install-from-fivemac.sh](playbooks/install-from-fivemac.sh) | Orchestrator on fivemac |

Implementation copies may also land in `marvelousempire/nephew` — this ledger is the **receipt of record** for yousirjuan.

## Replay (zero-AI)

From fivemac:

```bash
cd ~/Sites/yousirjuan
bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/install-from-fivemac.sh
# or: install-fleet-sharing
# or: cd ~/Developer/nephew && make fleet-sharing-install
```

On **onemac** (bootstrap kit auto-dropped to SeverD share):

```bash
cd /Volumes/SeverD/FleetBootstrap-LEDGER-0036
bash bootstrap-mac-fleet-ssh.sh
```

On **twomac** (Metal HD is read-only — use AirDrop or wait for SSH after onemac bootstrap):

```bash
bash ~/bootstrap-mac-fleet-ssh.sh
```

## Verification

```bash
# Names resolve (not docker bridges)
ping -c1 nephew-spark.local   # → 192.168.10.205
dns-sd -G v4 nephew-spark.local

# Mounts use hostnames in mount table
mount | grep nephew-spark.local
mount | grep twomac.local

# fivemac sharing: admin only
sharing -l -f json | python3 -m json.tool

# DGX SMB listening
ssh nephew-spark 'ss -tlnp | grep -E ":445|:139"'
```

## Undo

```bash
# Eject hostname mounts
diskutil unmount ~/Volumes/nephew-developer 2>/dev/null
diskutil unmount ~/Volumes/nephew-spark-home 2>/dev/null
diskutil unmount ~/Volumes/twomac-metal-hd 2>/dev/null

# Remove Mac hosts fallback (optional if mDNS alone is enough)
sudo sed -i '' '/nephew-spark.local/d' /etc/hosts

# Restore DGX avahi defaults only if needed — keep ledger copy first
```

## Notes

- **Session journal:** [journal.md](journal.md)
- **Clinic device registry:** `Developer/clinic/devices/registry.md` (fivemac/onemac/twomac/spark IPs)
- **Open:** onemac `SeverD` share still mounts manually; twomac SMB browse name still generic until `configure-mac-bonjour-name.sh` runs on twomac