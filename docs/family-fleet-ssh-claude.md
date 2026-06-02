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

| Host | Bootstrap admin | `claude` sudo | SSH key |
|---|---|---|---|
| VPS (Ubuntu) | existing operator user | NOPASSWD optional | Mac `ed25519` |
| DGX (Ubuntu arm64) | existing operator user | NOPASSWD optional | Mac `ed25519` |
| Flint (OpenWrt) | `admin` UI / `root` SSH | **no** NOPASSWD | Mac `ed25519` |
| Slate (OpenWrt) | `root` | **no** NOPASSWD | Mac `ed25519` |
| NAS (UGOS) | UGOS admin | **no** | Mac `ed25519` |
| Mac (macOS) | operator admin | off by default | Mac `ed25519` |

Routers: enable **System → Security → SSH → Enable SSH** (LAN). Prefer **Remote SSH
OFF** on WAN.

## Install order (from operator Mac)

1. Copy and fill `operator-hosts.env`.
2. `bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh`  
   Or per target: `vps` `dgx` `mt6000` `ax1800` `nas` `mac`.
3. Merge `artifacts/ssh-config-snippet.example` into `~/.ssh/config` (edit hosts first).
4. `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` (if key has passphrase).

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
ssh mac-claude 'whoami'
```

## Ledger entry

Full playbooks: [`ledger/LEDGER-0032-claude-ssh-user/`](../ledger/LEDGER-0032-claude-ssh-user/README.md).

## Related docs

- [`hardware-topology.md`](hardware-topology.md) — device roles (generic)
- [`LEDGER-0027` seed-to-tree](../ledger/LEDGER-0027-seed-to-tree-bootstrap/README.md) — full stack bootstrap

Legacy docs with operator-specific IPs (e.g. older whitepapers) may predate this
sanitization — treat **operator-hosts.env** as source of truth locally.
