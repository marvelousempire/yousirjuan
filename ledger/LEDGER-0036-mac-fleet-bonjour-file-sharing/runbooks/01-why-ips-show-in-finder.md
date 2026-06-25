# 01 — Why Finder Network shows IPs next to nice names

## Symptom

In **Finder → Network** you see both:

- `192.168.10.159` and `192.168.10.166` (with eject arrows)
- `MacBook Pro`, `AVERY's iMac`, `NASA` (friendly names)

## Root cause

These are **not the same kind of row**.

| Row | What it is |
|-----|------------|
| **Friendly name** | Bonjour browse (`_smb._tcp`) — a computer advertising File Sharing |
| **IP with eject** | An **active SMB mount** — the host string from when you connected |

If you used **Connect to Server** (`⌘K`) with `smb://192.168.10.159/...`, Finder labels that mount with the IP. The same physical Mac may also appear as **MacBook Pro** (its SMB Computer Name).

## Fix

1. **Eject** the IP-based mount (sidebar eject or `diskutil unmount`).
2. Reconnect with the hostname:

```
⌘K → smb://averygoodman@onemac.local/SeverD
⌘K → smb://averygoodman@twomac.local/Metal%20HD
⌘K → smb://abrownsanta@nephew-spark.local/Developer
```

3. Confirm:

```bash
mount | grep -v '@192\.168\.10\.'
```

You want `@onemac.local`, `@twomac.local`, `@nephew-spark.local` — not raw IPs.

## Rule

**Never use `192.168.10.x` in Connect to Server** unless mDNS is broken and you are debugging. IPs are emergency fallback only.