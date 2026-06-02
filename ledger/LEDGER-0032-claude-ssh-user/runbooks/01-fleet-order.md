# 01 — Fleet install order

## Why

Some hosts are only reachable from the **home LAN**; the VPS is reachable from
anywhere. Install in an order that lets you verify each hop.

## Prerequisites

1. Copy [`../artifacts/operator-hosts.env.example`](../artifacts/operator-hosts.env.example) → `operator-hosts.env` (gitignored).
2. Operator Mac pubkey at `~/.ssh/id_ed25519.pub`.

## Order

1. **Mac** — `bash …/playbooks/create-claude-user-mac.sh`
2. **VPS** — `install-from-mac.sh vps` (needs `operator-hosts.env`)
3. **DGX** — on home LAN: `install-from-mac.sh dgx`
4. **Flint** — `install-from-mac.sh mt6000` (`claude@192.168.8.1` when shipped)
5. **Slate** — `provision-ax1800-slate.sh` or manual on-router block (see [02](02-ax1800-nas-finish.md)) at `192.168.9.1`
6. **NAS** — enable SSH in UGOS, then `install-from-mac.sh nas`

## Success

Each host: `ssh claude@<target> true` works with the Mac key (no password prompt).

## Undo

```bash
sudo userdel -r claude
sudo rm -f /etc/sudoers.d/claude
```

On OpenWrt, also remove `/home/claude` and `claude` lines in `/etc/passwd` / `/etc/group`.
