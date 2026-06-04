# LEDGER-0032 — `claude` SSH user (family fleet)

**Status:** shipped (2026-06-02 fleet SSH; 2026-06-03 NAS NFS + DGX mount playbooks) — 8/8 `claude` targets + SME NAS storage on DGX.

Canonical public doc: [`docs/family-fleet-ssh-claude.md`](../../docs/family-fleet-ssh-claude.md)

## What

One **automation SSH identity** (`claude` + operator Mac `ed25519` pubkey) across the
family stack. Committed files use **placeholder LAN addresses** only; real targets
live in **`artifacts/operator-hosts.env`** (gitignored).

## Fleet map (placeholders)

| Host | Admin login (bootstrap) | `claude` sudo | Placeholder |
|---|---|---|---|
| **Public VPS** | `your-vps-user@your.vps.host:2222` | NOPASSWD optional | not LAN |
| **DGX Spark** | `your-dgx-user@your-dgx-host` (IPv6 alias common) | NOPASSWD optional | `192.168.8.x` |
| **Flint 2 (MT6000)** | `admin@` UI; `root@` or `claude@` SSH | no | `192.168.8.1` |
| **Slate (AX1800)** | `root@` UI + SSH | no | `192.168.9.1` (Flint WAN subnet) |
| **UGreen NAS** | UGOS admin + SSH | no | `192.168.8.x` |
| **Operator Mac** | macOS admin | off by default | `127.0.0.1` |

**Not a GL.iNet target:** `192.168.0.1` ISP gateway — no `claude` SSH.

## Operator setup (once per Mac)

```bash
cp ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env.example \
   ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env
# edit operator-hosts.env — real VPS host, DGX alias, etc.

cd ~/Developer/yousirjuan
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh
```

Merge [`artifacts/ssh-config-snippet.example`](artifacts/ssh-config-snippet.example) into
`~/.ssh/config` after editing hostnames.

## Replay

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh vps dgx mt6000 ax1800 mac
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/provision-ax1800-slate.sh   # needs SLATE_PASSWORD
```

## Runbooks

| # | Topic |
|---|---|
| [01](runbooks/01-fleet-order.md) | Install order |
| [02](runbooks/02-ax1800-nas-finish.md) | Slate + NAS notes |
| [03](runbooks/03-operator-local-config.md) | Gitignored local overrides |

## Shipped checklist

| Target | State |
|---|---|
| VPS `claude` | shipped — `AllowUsers` includes `claude` |
| DGX `claude` | shipped |
| Flint `claude@192.168.8.1` | shipped |
| Slate `claude@192.168.9.1` | shipped (manual on-router install path documented) |
| Mac `claude` | shipped — use `ssh-add` for passphrase keys |
| NAS | optional — UGOS SSH + `install-from-mac.sh nas` |

## Security

- Routers: **no** NOPASSWD for `claude`.
- VPS/DGX: NOPASSWD only where unattended deploys need it; remove `/etc/sudoers.d/claude` to opt out.
- Turn OFF WAN **SSH Remote Access** on GL.iNet; keep LAN SSH ON.
