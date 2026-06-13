# LEDGER-0032 — `claude` SSH user (family fleet)

**Status:** shipped (2026-06-02 fleet SSH; 2026-06-03 NAS NFS + DGX mount playbooks) — 8/8 `claude` targets + SME NAS storage on DGX.

Canonical public doc: [`docs/family-fleet-ssh-claude.md`](../../docs/family-fleet-ssh-claude.md)

## What

One **automation SSH identity** (`claude` + operator Mac `ed25519` pubkey) across the
family stack. Committed files use **placeholder LAN addresses** only; real targets
live in **`artifacts/operator-hosts.env`** (gitignored).

## Fleet map (placeholders)

| Host | Admin login (bootstrap) | `claude` sudo | Placeholder | Password from creation? |
|---|---|---|---|---|
| **Public VPS** | `your-vps-user@your.vps.host:2222` | NOPASSWD optional | not LAN | No (key only) |
| **DGX Spark** | `your-dgx-user@your-dgx-host` (IPv6 alias common) | NOPASSWD optional | `192.168.8.x` | **No (key only)** |
| **Flint 2 (MT6000)** | `admin@` UI; `root@` or `claude@` SSH | no | `192.168.8.1` | No (key only) |
| **Slate (AX1800)** | `root@` UI + SSH | no | `192.168.9.1` (Flint WAN subnet) | No (key only) |
| **UGreen NAS** | UGOS admin + SSH | no | `192.168.8.x` | No (key only) |
| **Operator Mac** | macOS admin | off by default | `127.0.0.1` | Yes (random, Keychain on that Mac) |

**Not a GL.iNet target:** `192.168.0.1` ISP gateway — no `claude` SSH.

## Operator setup (once per Mac) — unified & protected

All live secrets (CLAUDE_PASSWORD, SSH hosts, member bootstraps, etc.) must live in a single protected file that AI agents are **forbidden** to read.

Recommended:
```bash
mkdir -p ~/.config/tower
chmod 700 ~/.config/tower
# Create ~/.config/tower/tower.env with 600 perms (see .example for keys)
chmod 600 ~/.config/tower/tower.env
```

Then use the single unified command (sources tower.env automatically):

```bash
cd ~/Developer/yousirjuan
scripts/fleet-claude install dgx vps          # or macs, bigmac, etc.
scripts/fleet-claude password dgx vps
scripts/fleet-claude member add avery dgx
scripts/fleet-claude member list
```

The old per-playbook calls still work for compatibility, but `fleet-claude` is the recommended entry point.

Copy the example only for reference:
```bash
cp ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env.example \
   ~/.config/tower/tower.env
# edit the real tower.env (never commit it)
```

Merge the ssh config snippet as before.

## Replay

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh vps dgx mt6000 ax1800 mac
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/set-claude-password.sh dgx vps   # generate/apply CLAUDE_PASSWORD
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/add-member.sh avery dgx vps   # for human Members + ACL
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/provision-ax1800-slate.sh   # needs SLATE_PASSWORD
```

## Runbooks

| # | Topic |
|---|---|
| [01](runbooks/01-fleet-order.md) | Install order |
| [02](runbooks/02-ax1800-nas-finish.md) | Slate + NAS notes |
| [03](runbooks/03-operator-local-config.md) | Gitignored local overrides |
| [07](runbooks/07-add-member.md) | Add a human Member with full ACL (new) |

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

## Passwords (AI / `claude` users)

The `claude` automation users were created with **deliberately minimal credentials**:

- **DGX, VPS and other Linux targets:** No password is ever set by `create-claude-user.sh`.  
  Only the operator ed25519 key + (on DGX/VPS) NOPASSWD sudo.  
  The account is unlocked (`usermod -U`) but has no password hash.  
  Use the dedicated SSH aliases (`dgx-claude`, `clinic-vps-claude`, etc.).  
  From the admin account on the box: `sudo -u claude -i`.

- **macOS fleet machines:** A random password (`openssl rand -base64 24`) is generated inside `create-claude-user-mac.sh` and fed to `sysadminctl`. It is never persisted in any file or git. It lives only in the target Mac's Keychain / local auth.  
  Reset on the target Mac (as admin): `sudo sysadminctl -resetPassword -user claude`.

### Default password for the claudes (take it from here)

The **default password** for the claude AI/automation users lives in the local (gitignored) file in this same directory:

**`artifacts/operator-hosts.env`**

Look for the line:

`CLAUDE_PASSWORD=...`

Just open that file (or run `grep CLAUDE_PASSWORD artifacts/operator-hosts.env` from this dir) and copy the value when you need to set the password on DGX or other Linux claude accounts.

The file also has copy-paste usage commands right above the password line.

The install playbooks now automatically consume `CLAUDE_PASSWORD` (when present) and pass it through so `create-claude-user.sh` sets the password on Linux targets (DGX, VPS, etc.) during normal runs.

### Adding Members (human family / operator accounts) + ACL

The same infrastructure now supports adding real **Members** (human family members / operators) in addition to the shared `claude` AI automation account, with full **ACL** handling:

- Per-user SSH key
- Optional password (use `CLAUDE_PASSWORD` or per-invocation)
- sudo access (NOPASSWD controllable via `NOPASSWD_SUDO=1|0`)
- SSH ACL via `sshd_config.d` AllowUsers append (when a restrictive drop-in exists)
- Proper groups (sudo, wheel, admin where relevant)
- macOS equivalents (access_ssh group + sudoers)

**How to add a Member:**

```bash
# Example: add "avery" to a Linux target (DGX/VPS/etc.)
ssh admin@target-host \
  "sudo env USER_NAME=avery \
        PUBKEY='ssh-ed25519 AAAA...avery-pubkey...' \
        PASSWORD='from-operator-hosts-or-other' \
        NOPASSWD_SUDO=1 \
        bash -s" < playbooks/create-claude-user.sh

# For a Mac target, use/adapt create-claude-user-mac.sh with similar env (PASSWORD supported)
```

Store per-member bootstrap info and keys in your local `operator-hosts.env` (gitignored) for repeatability.

Guidance and examples are also in `artifacts/operator-hosts.env` (local copy).

This ensures consistent ACL whether provisioning the AI `claude` user or new human Members.

See the public doc for more details: [`docs/family-fleet-ssh-claude.md`](../../docs/family-fleet-ssh-claude.md#credential-model-all-devices)

Bootstrap passwords (for initial admin/root on routers/NAS during provisioning) are prompted at runtime only and are not for the `claude` accounts themselves.
