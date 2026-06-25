# Session journal — 2026-06-25 — Mac fleet Bonjour file sharing

**Operator:** Avery (`averygoodman` on **fivemac**)
**Agent:** Grok via Cursor on fivemac
**Working directory:** `/Users/averygoodman` (+ `Developer/nephew`, `Sites/yousirjuan`)
**Outcome:** nephew-spark and twomac mount in Finder by **Bonjour hostname**; fivemac File Sharing is **admin-only**; root mDNS bug on DGX documented and fixed; onemac/twomac bootstrap path defined.

---

## What this session is

An **infrastructure-and-operator-UX session** — not a product feature. Goal: make the Family Office Mac mesh behave like Apple intends: browse **Network** in Finder, see friendly names, connect to **nephew-spark** (Linux DGX) and peer Macs without memorizing `192.168.10.x` addresses.

---

## Chronological narrative

### Moment 1 — "How do I connect to nephew-spark.local from fivemac?"

Confirmed both machines on `192.168.10.0/24` (GL-MT6000). SSH alias `nephew-spark` → `abrownsanta@nephew-spark.local` with dedicated key already in `~/.ssh/config`. Ping and SSH worked.

### Moment 2 — "On my Mac I could just see another Mac's files in Finder"

Explained macOS **File Sharing** over SMB + Bonjour (`_smb._tcp`). On LAN: MacBook Pro = onemac, AVERY's iMac = bigmac, fivemac, NASA. nephew-spark is Linux — needs Samba or SFTP, not native Mac sharing.

### Moment 3 — "I want all of that"

**On nephew-spark (DGX):**
- Deployed Samba (`Developer`, `[homes]`) for `abrownsanta`
- Avahi `_smb._tcp` service as `nephew-spark`
- SMB password in macOS Keychain (`nephew-spark-smb`)
- LaunchAgent `com.marvelousempire.nephew-spark-mounts` on fivemac

**On fivemac:**
- SFTP via `sftp://abrownsanta@nephew-spark.local`
- SMB mounts at `~/Volumes/nephew-developer`, `~/Volumes/nephew-spark-home`

### Moment 4 — "Yes — onemac/twomac too, admin only, connection failed"

**Connection failed:** `ping nephew-spark.local` → *Unknown host* while `192.168.10.205` worked. `dscacheutil` showed only IPv6 link-local for nephew-spark; Docker bridges on DGX caused avahi to publish `192.168.128.1` as the A record.

**Workaround (temporary):** `/etc/hosts` entry + mount scripts preferring IP → Finder showed **IPs**.

**Admin-only on fivemac:** Removed guest shares (Public folders, whole-disk `Macintosh HD`); only `averygoodman` home SMB share with `guest access: 0`.

**onemac/twomac:** No SSH key from fivemac — bootstrap script required on each peer Mac.

### Moment 5 — "I don't want IP addresses showing — I want nice names"

**Key insight (operator screenshot):** Finder Network listed **192.168.10.159** and **192.168.10.166** *with eject arrows* because those volumes were **mounted via IP**, while **MacBook Pro** and **NASA** appeared as Bonjour names for unmounted browse entries.

| Sidebar entry | Meaning |
|---------------|---------|
| `192.168.10.159` | onemac — `SeverD` share mounted via IP |
| `192.168.10.166` | twomac — `Metal HD` share mounted via IP |
| `MacBook Pro` | same machine as onemac (its SMB Computer Name) |
| `nephew-spark` | DGX (after Samba + avahi fix) |

**Fix:** Remount with `//user@nephew-spark.local/share` not `//user@192.168.10.205/share`. Reverted SSH `HostName` to `nephew-spark.local`.

**DGX avahi (permanent):**
```
allow-interfaces=enx6c6e072c96c6
deny-interfaces=docker0,lo,br-*,veth*,wg0
/etc/avahi/hosts → 192.168.10.205 nephew-spark.local
```

After fix: `avahi-resolve -4 -n nephew-spark.local` → `192.168.10.205`; `mount` shows `nephew-spark.local`.

### Moment 6 — "Report it all in yousirjuan"

This ledger entry + PAIN-0011/0012 + CHANGELOG + Feature Ledger + HANDOFF update.

---

## Surprises and pivots

1. **Two different "names" on Macs** — `LocalHostName` (`onemac.local`) vs SMB **Computer Name** (`MacBook Pro`). Both valid; operator wants fleet tags (`onemac`, `twomac`) aligned via `scutil --set ComputerName`.
2. **Mounted ≠ browsed** — A mounted SMB volume appears in Network under the **connection URL host**, not necessarily the `_smb._tcp` instance name.
3. **Docker on AI island poisons mDNS** — same class of bug as nephew-spark; deny `br-*` and `veth*` on avahi.
4. **SFTP `open` URL fails headless** — `open sftp://...` needs Finder handler; use ⌘K interactively or SSH for automation.
5. **Scripts in nephew repo were ephemeral** — some session scripts did not persist on disk; playbooks in **this ledger** are the durable copy.

---

## State after session (fivemac)

| Component | Value |
|-----------|-------|
| nephew-spark Developer mount | `//abrownsanta@nephew-spark.local/Developer` → `~/Volumes/nephew-developer` |
| nephew-spark home mount | `//abrownsanta@nephew-spark.local/abrownsanta` → `~/Volumes/nephew-spark-home` |
| twomac Metal HD | `//averygoodman@twomac.local/Metal HD` |
| fivemac SMB shares | `averygoodman` only, guest off |
| fivemac ComputerName | `fivemac` |
| LaunchAgents | `com.marvelousempire.nephew-spark-mounts`, `com.marvelousempire.mac-fleet-mounts` |
| SSH nephew-spark | `HostName nephew-spark.local` |

---

## Open follow-ups

- [ ] On **onemac**: open `/Volumes/SeverD/FleetBootstrap-LEDGER-0036/` → run `bash bootstrap-mac-fleet-ssh.sh`
- [ ] On **twomac**: Metal HD share is **read-only** — copy bootstrap kit via AirDrop or run from fivemac scp after SSH works
- [ ] Re-run `install-fleet-sharing` after onemac bootstrap (enables remote SSH configure)
- [ ] Rename onemac SMB browse name: `MacBook Pro` → `onemac` (optional — `configure-mac-bonjour-name.sh`)
- [x] Playbooks mirrored to `Developer/nephew/scripts/` + `make fleet-sharing-install`
- [x] LaunchAgents point at yousirjuan ledger playbooks
- [x] All active mounts use `*.local` hostnames (2026-06-25 PM verify)

---

## Cross-links

- [journal.md](journal.md) (this file)
- [PAIN-0011](../../pain-journal/PAIN-0011-finder-shows-ip-not-bonjour-name.md)
- [PAIN-0012](../../pain-journal/PAIN-0012-dgx-docker-pollutes-mdns.md)
- Nephew clinic registry: `Developer/clinic/devices/registry.md`
- Home network: `docs/home-network-full-architecture-report.md`