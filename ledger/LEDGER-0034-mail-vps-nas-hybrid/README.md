# LEDGER-0034 — Mail hybrid: VPS live + NAS over WireGuard (rsync + NFS mount)

**MX/DNS stay on VPS** (`mail.jailynmarvin.com` → edge). Mailbox **files** get a **NAS copy** over WG and optionally **live** on an NFS mount once the NAS share exists.

## Architecture

```
Internet → MX → VPS docker-mailserver (Postfix/Dovecot)
                    │
                    ├─ primary: /opt/mail-jailynmarvin/docker-data/dms/mail-data/  (VPS disk)
                    │
                    └─ WireGuard 10.0.0.5 → 192.168.8.204
                           ├─ NFS mount: /mnt/nas-mail-vault
                           ├─ rsync backup → …/backup/jailynmarvin-mail/
                           └─ (optional) live mail-data bind → NAS mount
```

## Operator order

1. **UGOS (NAS)** — [runbooks/01-nas-ugos-mail-share.md](runbooks/01-nas-ugos-mail-share.md)
2. **VPS** — `sudo bash playbooks/install-nas-hybrid.sh`
3. **Verify** — `sudo bash playbooks/preflight-nas-mail.sh`
4. **Optional live on NAS** — only after preflight green: `LIVE_MAIL_ON_NAS=1 sudo bash playbooks/install-nas-hybrid.sh`

## Replay

```bash
scp -r ledger/LEDGER-0034-mail-vps-nas-hybrid/playbooks clinic-vps:/tmp/ledger-0034-mail-nas/
ssh clinic-vps 'sudo bash /tmp/ledger-0034-mail-nas/install-nas-hybrid.sh'
```

## Status

`blocked-on-nas-share` until NFS is enabled and `192.168.8.204` answers from VPS over WG.
