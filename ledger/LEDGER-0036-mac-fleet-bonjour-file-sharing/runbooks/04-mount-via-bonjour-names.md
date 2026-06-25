# 04 — Mount fleet hosts via Bonjour names (fivemac)

## nephew-spark (DGX)

```bash
bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/ensure-nephew-spark-mounts.sh
```

Mounts:

| Share | Path on fivemac |
|-------|-----------------|
| `Developer` | `~/Volumes/nephew-developer` |
| `abrownsanta` (home) | `~/Volumes/nephew-spark-home` |

SMB user: `abrownsanta` — password in Keychain service `nephew-spark-smb`.

## Peer Macs (onemac / twomac)

```bash
bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/ensure-mac-fleet-mounts.sh
```

| Host | Share | Mount path |
|------|-------|------------|
| onemac.local | SeverD | `~/Volumes/onemac-severd` |
| twomac.local | Metal HD | `~/Volumes/twomac-metal-hd` |

## LaunchAgents (optional auto-remount)

```bash
# Copy plist templates or run install-from-fivemac.sh
launchctl list | grep marvelousempire
```

- `com.marvelousempire.nephew-spark-mounts` — every 5 min
- `com.marvelousempire.mac-fleet-mounts` — every 10 min

## Manual Finder

```
⌘K → smb://abrownsanta@nephew-spark.local/Developer
⌘K → smb://averygoodman@onemac.local/SeverD
⌘K → smb://averygoodman@twomac.local/Metal%20HD
⌘K → sftp://abrownsanta@nephew-spark.local
```