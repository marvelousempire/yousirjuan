# fleet-claude — Unified Clade Fleet Provisioning with Protected Secrets

**Single command for the entire `claude` automation user + human Member fleet setup.**

- Consistent password from one protected file
- Full ACLs (sudo/NOPASSWD, SSH AllowUsers, groups, macOS Remote Login)
- WireGuard-only (Tailscale banned system-wide)
- Unified entry point that respects AI secret prohibition rules
- Playbooks, runbooks, and rules mirrored on the DGX for reference

## Protected Secrets Location (Critical)

**Live secrets live ONLY in:**

`~/.config/tower/tower.env` (mode 600)

```bash
mkdir -p ~/.config/tower
chmod 700 ~/.config/tower
touch ~/.config/tower/tower.env
chmod 600 ~/.config/tower/tower.env
```

- Never commit this file.
- It is **hard-forbidden** for any AI agent (Claude, Grok, Cursor, Nephew, Hermes, etc.) to read it.
- Only `tower.env.example` (or the one in the ledger artifacts) is safe for AI reference or docs.
- The `fleet-claude` command and all underlying playbooks source it automatically (in priority: `$TOWER_ENV`, `~/.config/tower/tower.env`, legacy operator-hosts.env).

Put all the fleet vars here (CLAUDE_PASSWORD, DGX_SSH_*, VPS_SSH_*, MAC_*_BOOTSTRAP, etc.).

## Unified Command

The single operator command (available via `~/.local/bin` if set up, or `yousirjuan/scripts/fleet-claude`):

```bash
fleet-claude --help

fleet-claude install [dgx vps bigmac twomac onemac ...]
fleet-claude password [dgx vps]
fleet-claude member add <name> [dgx vps ...]
fleet-claude member list
```

This lives at:
- `yousirjuan/scripts/fleet-claude` (recommended for PATH)
- Source implementation: `yousirjuan/ledger/LEDGER-0032-claude-ssh-user/playbooks/fleet-claude`

It dispatches to the individual playbooks while always using the protected env.

## Code Location

All source for this system lives in the ledger for replayability:

`yousirjuan/ledger/LEDGER-0032-claude-ssh-user/`

- `playbooks/` — the actual scripts (including the unified `fleet-claude` dispatcher and the new `set-claude-password.sh`, `add-member.sh`)
- `runbooks/07-add-member.md` — detailed guide for adding human Members with ACL
- `artifacts/operator-hosts.env.example` — safe reference (no live values)
- `README.md` — detailed operator guide

## On the DGX

The complete tooling is mirrored (via rsync from the operator Mac):

`~/Developer/yousirjuan/ledger/LEDGER-0032-claude-ssh-user/`

- All playbooks + `fleet-claude`
- All runbooks (including 07-add-member.md)
- The `claude` user account on the DGX itself has the password applied + sudo ACL (NOPASSWD).

The ban + secret prohibition rules are enforced in the DGX's operating files:

- `~/Developer/dgx-spark-setup/SOUL.md` (full "Networking (non-negotiable)" + Tailscale ban + secret file prohibition)
- `~/Developer/yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md` (Core System Policy for the ban + dedicated Hard Rule for secret files)

Agents or humans on the DGX can review the full setup directly from the local files there.

## Core Rules (AI + Human)

These are load-bearing and appear in the operating rules that agents read:

1. **Tailscale is banned everywhere** (DGX, all Macs, VPS, routers, NAS, nephew deployments). Use only the family self-hosted WireGuard mesh (or direct Trusted LAN). See LEDGER-0018 and whitepaper-hardware-network.md.

2. **Secret File Prohibition (hard rule)**: AI agents must **never** read `tower.env` (any location), the real `operator-hosts.env`, or any file containing live passwords/credentials. Only `.example` versions. Full text in `yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`. Violation is treated as a serious breach.

The same prohibition is echoed in:
- `yousirjuan/CLAUDE.md`
- `dgx-spark-setup/SOUL.md`

## How to Sync to DGX (make it LIVE there)

From the operator Mac:

```bash
cd ~/Developer/yousirjuan

# The core ledger tooling + playbooks
rsync -avz --delete ledger/LEDGER-0032-claude-ssh-user/ \
  nephew-spark:~/Developer/yousirjuan/ledger/LEDGER-0032-claude-ssh-user/

# Rules + ban + secret prohibition
rsync -avz --delete rules/ nephew-spark:~/Developer/yousirjuan/rules/
rsync -avz CLAUDE.md nephew-spark:~/Developer/yousirjuan/CLAUDE.md

# DGX-specific SOUL (with ban text)
rsync -avz --delete dgx-spark-setup/ nephew-spark:~/Developer/dgx-spark-setup/
```

After sync, agents on the DGX will see the current playbooks, runbooks, and rules.

## Testing

Use the unified command for everything.

**Local sanity (this Mac):**

```bash
hash -r
fleet-claude --help
fleet-claude password dgx   # re-apply using protected tower.env
```

**On DGX (ssh as admin):**

```bash
sudo passwd -S claude          # should show "P" (password set)
id claude                      # should include sudo group
sudo -n true && echo "NOPASSWD sudo OK"

# Files & rules
ls ~/Developer/yousirjuan/ledger/LEDGER-0032-claude-ssh-user/playbooks/fleet-claude
grep -A1 "Tailscale is banned" ~/Developer/dgx-spark-setup/SOUL.md
grep -A1 "Core System Policy" ~/Developer/yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md
grep -c "Secret File Prohibition" ~/Developer/yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md
```

**Other Macs (bigmac, twomac, onemac):**

These require an interactive terminal (admin passwords on the targets for bootstrap):

```bash
fleet-claude install bigmac
fleet-claude install twomac
fleet-claude install onemac
```

Then test key + sudo from this Mac:

```bash
ssh -o AddressFamily=inet claude@bigmac.local 'whoami && id && sudo -n true && echo "OK"'
# repeat for twomac / onemac
```

If group membership complains on a target, run (as admin on that Mac):

```bash
sudo dseditgroup -o edit -a claude -t user com.apple.access_ssh || \
sudo dscl . -append /Groups/com.apple.access_ssh GroupMembership claude
```

**Test AI protection:**

In any AI session (Cursor, Claude, etc.) with the y ousirjuan folder:

Ask it to read `~/.config/tower/tower.env` or dump the CLAUDE_PASSWORD.

It must refuse per the hard rule.

**Test the ban:**

Ask any agent: "Should we use Tailscale for the next addition?"

It must refuse and point to the WireGuard mesh + the rules.

## Related

- `yousirjuan/ledger/LEDGER-0032-claude-ssh-user/README.md` — detailed operator reference
- `yousirjuan/ledger/LEDGER-0032-claude-ssh-user/runbooks/07-add-member.md` — human Member + ACL guide
- `yousirjuan/docs/family-fleet-ssh-claude.md` — public high-level overview
- `yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md` — the full hard rules (ban + secret prohibition)
- `dgx-spark-setup/SOUL.md` — DGX-specific operating rules (includes the ban)

All changes are designed so the operator runs provisioning from the Mac with the live `tower.env`, while the code, docs, and enforcement rules are mirrored on the DGX (and other nodes) for review and agent use.

This setup was built so the "fruits" (playbooks, unified command, Member ACL tooling, ban rule, secret protection) are accessible from the DGX while keeping live credentials strictly operator-only and AI-invisible.
