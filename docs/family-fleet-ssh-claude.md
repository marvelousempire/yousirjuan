# Family fleet — `claude` SSH automation user

Public, committable reference for the **LEDGER-0032** playbooks. Real hostnames,
operator usernames, and public IPs live only in a **local gitignored** file on the
operator Mac.

## Privacy model

| In git (this repo) | Local only (never commit) |
|---|---|
| Role names, device models, subnet patterns (`192.168.8.x`) | VPS hostname, SSH users, IPv6 aliases |
| GL.iNet UI login conventions (`admin` vs `root`) | Passwords, API keys, pubkey comments |
| Playbooks and runbooks | `ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env` |
| `ssh-config-snippet.example` | Your merged `~/.ssh/config` |

```bash
cp ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env.example \
   ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env
# edit operator-hosts.env with your real values
```

## Network roles (placeholder addresses)

Typical **double-NAT** home lab with GL.iNet Flint + Slate:

```
ISP gateway          192.168.0.1     (edge — web only, no claude SSH)
    │
GL.iNet Slate        192.168.9.1     (upstream of Flint WAN — SSH user: root)
    │
GL.iNet Flint 2      192.168.8.1     (inner LAN gateway — UI: admin, SSH: root/claude)
    ├── DGX Spark      192.168.8.x     (inner LAN — prefer IPv6 alias if IPv4 flaky)
    ├── NAS            192.168.8.x     (UGOS — SSH optional)
    └── Operator Mac   192.168.8.x

Public VPS           (your hostname)   port 2222 typical — claude + AllowUsers
```

**Do not confuse:**

- `192.168.0.1` — ISP modem/gateway UI (e.g. carrier “router” branding).
- `192.168.9.1` — **Slate** GL.iNet admin (same UI skin as Flint, different password).
- `192.168.8.1` — **Flint** inner gateway.

## `claude` user policy

| Host | Bootstrap admin | `claude` sudo | SSH key | Password set by fleet? |
|---|---|---|---|---|
| VPS (Ubuntu) | existing operator user | NOPASSWD optional | Mac `ed25519` | No (key only) |
| DGX (Ubuntu arm64) | existing operator user | NOPASSWD optional | Mac `ed25519` | **No** (key only) |
| Flint (OpenWrt) | `admin` UI / `root` SSH | **no** NOPASSWD | Mac `ed25519` | No (key only) |
| Slate (OpenWrt) | `root` | **no** NOPASSWD | Mac `ed25519` | No (key only) |
| NAS (UGOS) | UGOS admin | **no** | Mac `ed25519` | No (key only) |
| Mac (macOS) — ONEMAC, BigMac, TWOMAC, … | operator admin (bootstrap once) | off by default | **same** Mac `ed25519` | Yes (random per Mac, Keychain only on target) |

See [Credential model](#credential-model-all-devices) below for exact commands to inspect/set/reset.

Routers: enable **System → Security → SSH → Enable SSH** (LAN). Prefer **Remote SSH
OFF** on WAN.

## Install order (from operator Mac)

1. Copy and fill `operator-hosts.env`.
2. `bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh`  
   Or per target: `vps` `dgx` `mt6000` `ax1800` `nas` `mac` `onemac` `bigmac` `twomac` `macs`.
3. **LAN Macs:** set `MAC_*_BOOTSTRAP` in `operator-hosts.env`, enable **Remote Login** on each Mac, then `bigmac` / `twomac` (password prompt) or `macs` for all.
4. Merge `artifacts/ssh-config-snippet.example` into `~/.ssh/config` (edit hosts first).
5. `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` (if key has passphrase).

## Slate (AX1800) manual path (when already `root@` on router)

If you are logged into the Slate shell (`root@GL-AXT1800`), run on **the router**:

```sh
PUBKEY='ssh-ed25519 AAAA… your-operator-pubkey-line'
id claude >/dev/null 2>&1 || { echo 'claude:x:1000:1000:Claude:/home/claude:/bin/ash' >> /etc/passwd; echo 'claude:x:1000:' >> /etc/group; }
mkdir -p /home/claude/.ssh
grep -qF "$PUBKEY" /home/claude/.ssh/authorized_keys 2>/dev/null || echo "$PUBKEY" >> /home/claude/.ssh/authorized_keys
chown -R claude:claude /home/claude
chmod 700 /home/claude/.ssh
chmod 600 /home/claude/.ssh/authorized_keys
```

Then from the **Mac**: `ssh claude@192.168.9.1 id`.

## Verify (placeholders)

```bash
ssh clinic-vps-claude 'sudo -n true && echo vps-ok'
ssh dgx-claude 'hostname'
ssh mt6000-claude 'echo flint-ok'
ssh ax1800-claude 'id'
ssh onemac-claude 'whoami'
ssh bigmac-claude 'whoami'
ssh twomac-claude 'whoami'
ssh mac-claude 'whoami'
```

## Credential model (all devices)

- **One operator key:** `~/.ssh/id_ed25519` (comment e.g. `mac-nivram-2025-09-25`) is installed into each host’s `claude` `authorized_keys`.

- **Linux / DGX / VPS `claude` users (the main AI automation account on servers):**  
  The creation playbooks (`create-claude-user.sh`) intentionally set **no password**.  
  - `useradd -m -s /bin/bash claude`  
  - Adds sudo/wheel groups + `usermod -U claude` (unlocks account)  
  - Only the operator SSH key goes into `authorized_keys`  
  - On DGX + VPS: also creates `/etc/sudoers.d/claude` for `NOPASSWD:ALL`  
  There is no password hash. Password SSH or plain `su` will not work.  
  **Access:** `ssh dgx-claude` (or `ssh clinic-vps-claude` etc.) using your key.  
  From the admin account on the box you can also `sudo -u claude -i` or `sudo su - claude`.  
  **Inspect / set (from admin account):**  
  ```bash
  ssh nephew-spark 'sudo passwd -S claude'           # status (usually no usable password)
  ssh nephew-spark 'sudo grep "^claude:" /etc/shadow'
  ssh nephew-spark 'sudo passwd claude'              # set one if you ever need it for su/console
  ```

  **Default password value:** The standard one to use is in the local gitignored file for the playbooks:  
  `yousirjuan/ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env` (variable `CLAUDE_PASSWORD`).  
  Open it or grep the line and take the value from there.

  The `install-from-mac.sh` + `create-claude-user.sh` now automatically use `CLAUDE_PASSWORD` (when present in the env) to set the password on Linux targets.

- **macOS `claude` / "Claude Agent" users (on onemac, bigmac, twomac, etc.):**  
  A strong random password is generated at creation (`PW=$(openssl rand -base64 24)` in `create-claude-user-mac.sh`) and passed directly to `sysadminctl -addUser ... -password "$PW"`.  
  The value is **never printed or written to any file** in the playbooks. Per design it "lives in Keychain on that Mac only".  
  **Reset on the target Mac (as local admin):**  
  ```bash
  sudo sysadminctl -resetPassword -user claude
  # or
  sudo dscl . -passwd /Users/claude
  ```

- **No fleet passwords in git:** Bootstrap/admin passwords for initial hops (Slate, NAS, etc.) are prompted interactively at run time (osascript / read -s) and never committed. Use `operator-hosts.env` comments locally only if you must note something.

- **Default password for the claudes:** All live secrets live in one protected file that AI agents are strictly forbidden to read:

  Recommended location: `~/.config/tower/tower.env` (chmod 600)

  The unified command `yousirjuan/scripts/fleet-claude` (or `ledger/.../playbooks/fleet-claude`) sources it automatically.

  Legacy location (still works): the gitignored `operator-hosts.env` next to the ledger playbooks.

  Never put the real file inside the y ousirjuan tree or any directory that AI tools scan. Only the `.example` is safe for AI reference.

## Adding Members (with ACL)

The playbooks and creator scripts (`create-claude-user.sh`, `create-claude-user-mac.sh`, `install-from-mac.sh`) are built to also provision **human Members** (family / operator accounts) with proper **ACL**:

- Their own username (not just the shared `claude` AI account)
- SSH public key
- Optional password (via `PASSWORD=` or the shared `CLAUDE_PASSWORD`)
- sudo (configurable NOPASSWD)
- SSH access ACL (`AllowUsers` append when applicable)
- Correct groups and macOS Remote Login allowlist

See:
- Internal: `ledger/LEDGER-0032-claude-ssh-user/README.md` (Adding Members section)
- Wrapper: `playbooks/add-member.sh`
- Runbook: `runbooks/07-add-member.md`
- Local env: `artifacts/operator-hosts.env` (for CLAUDE_PASSWORD + member notes)
- **Dedicated operational guide:** `docs/fleet-claude.md` (unified `fleet-claude` command, protected `~/.config/tower/tower.env`, full setup, DGX sync, testing, and AI secret prohibition rules). Also available on the DGX at `~/Developer/yousirjuan/docs/fleet-claude.md`.

This lets you consistently add new family members to the fleet SSH + access control surface (ACL).

- **Bootstrap SSH:** first hop uses each machine’s **admin** account (`MAC_BIGMAC_BOOTSTRAP`, `NAS_SSH`, etc.) only until `claude@` accepts the pubkey.

## Ledger entry

Full playbooks: [`ledger/LEDGER-0032-claude-ssh-user/`](../ledger/LEDGER-0032-claude-ssh-user/README.md).

## Related docs

- [`hardware-topology.md`](hardware-topology.md) — device roles (generic)
- [`LEDGER-0027` seed-to-tree](../ledger/LEDGER-0027-seed-to-tree-bootstrap/README.md) — full stack bootstrap

Legacy docs with operator-specific IPs (e.g. older whitepapers) may predate this
sanitization — treat **operator-hosts.env** as source of truth locally.
