# Runbook 01 — NAS share for mail (UGOS)

Do this in the UGOS web UI (`https://nasa.local:9999` or `192.168.8.204:9999`).

## 1. Shared folder

Control Panel → **Shared Folder** → Create:

| Field | Value |
|--------|--------|
| Name | `mailvault` |
| Volume | your existing pool |
| Quota | none (or set a cap) |

## 2. NFS (for VPS WG mount)

Control Panel → **File Services** → **NFS** → Enable.

Add NFS rule on `mailvault`:

| Field | Value |
|--------|--------|
| Client | `192.168.8.0/24` |
| Access | Read/Write |
| Squash | Map to admin / share owner |

Add second rule:

| Field | Value |
|--------|--------|
| Client | `10.0.0.5` |
| Access | Read/Write |

(That is clinic-vps on the family WireGuard mesh.)

Note the export path UGOS shows (often `/volume1/mailvault` — set `NAS_NFS_EXPORT` on VPS to match).

## 3. SMB (optional — Mac backup browse)

File Services → **SMB** → Enable on `mailvault`.

Host allow: `192.168.8.0/24` only (inner LAN).

## 4. Firewall

Ensure inner LAN and WG clients can reach **NFS 2049** (and SMB 445 if used).

## 5. Verify from Mac (LAN)

```bash
ping -c 2 192.168.8.204
showmount -e 192.168.8.204
```

## 6. Verify from VPS (WireGuard)

```bash
ssh clinic-vps 'sudo bash /opt/mail-jailynmarvin/playbooks/preflight-nas-mail.sh'
```

Expect: ping OK, port 2049 open, mount OK.
