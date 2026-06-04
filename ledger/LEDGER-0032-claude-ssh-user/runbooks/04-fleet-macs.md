# 04 — Fleet Macs (ONEMAC, BigMac, TWOMAC)

## Goal

Same **`claude`** automation user and **one** operator `ed25519` pubkey on every Mac on the inner LAN.

## Roster (typical)

| Bonjour | Role | Remote Login | `claude` key SSH |
|---|---|---|---|
| **ONEMAC** | Operator MacBook (this machine) | on | local `mac` / `onemac` target |
| **BigMac** | iMac / desk Mac | must be on | `bigmac` target |
| **TWOMAC** | Second MacBook | must be on | `twomac` target |

LAN IPs drift with DHCP — use **ComputerName.local** in `operator-hosts.env` and `~/.ssh/config`.

If a `.local` name returns **multiple IPs** (e.g. BigMac on Wi‑Fi and Ethernet), pin one address on ONEMAC:

```bash
# Optional — only if SSH hits the wrong interface
sudo sh -c 'grep -q bigmac.local /etc/hosts || echo "192.168.8.182 bigmac.local" >> /etc/hosts'
```

Or assign a **DHCP reservation** on the Flint for each Mac.

## operator-hosts.env

```bash
MAC_ONEMAC_HOST=192.168.8.x
MAC_ONEMAC_BOOTSTRAP=nivram@192.168.8.x

MAC_BIGMAC_HOST=192.168.8.x
MAC_BIGMAC_BOOTSTRAP=nivram@192.168.8.x

MAC_TWOMAC_HOST=192.168.8.x
MAC_TWOMAC_BOOTSTRAP=nivram@192.168.8.x
```

Replace `nivram` with the admin short name on that Mac if different.

## Install

**This Mac only:**

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh mac
```

**Another Mac on LAN** (from ONEMAC, in Terminal — password prompts):

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh bigmac
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh twomac
```

Or all Macs:

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh macs
```

**At the console** (if SSH bootstrap fails): run `create-claude-user-mac.sh` on that Mac while logged in as admin.

## SSH config aliases

Merge from `artifacts/ssh-config-snippet.example`: `onemac-claude`, `bigmac-claude`, `twomac-claude`, `mac-claude` (localhost).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Connection refused` | System Settings → Sharing → **Remote Login** ON |
| `Permission denied` for admin@ | Wrong user/password; on BigMac confirm admin short name is `nivram` (System Settings → Users) |
| `Too many authentication failures` | Re-run from **Terminal.app**; script now uses password-only bootstrap (no pubkey flood) |
| `Pseudo-terminal will not be allocated` | Runner has no TTY — use **Terminal.app**, not a headless agent panel |
| `Connection closed` after `Server accepts key` | Add `claude` to **Remote Login allow list**: re-run bootstrap (fixed script) or `sudo dseditgroup -o edit -a claude -t user com.apple.access_ssh` on that Mac; or Sharing → **All users** |
| `Permission denied` for claude@ | Re-run `bigmac` / `twomac` bootstrap or on-console `create-claude-user-mac.sh` |
| Host key changed | `ssh-keygen -R 192.168.8.x` |
