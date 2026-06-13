# 07 — Add a Member (human family/operator account) with ACL

This extends the `claude` automation user fleet (LEDGER-0032) to real people.

## When to use
- Onboarding a new family member / operator (Avery, Bobby, Nivram, Yousir Juan, future members).
- Giving them SSH access to the fleet (DGX, VPS, Macs, routers, NAS) with proper ACL.
- Consistent with how the shared `claude` AI user is provisioned.

## Prerequisites
- The new Member has an SSH keypair (pubkey ready).
- You have admin/root access to the target machines (bootstrap).
- `operator-hosts.env` (local, gitignored) has `CLAUDE_PASSWORD` (or per-member `NAME_PASSWORD`) if you want a login password in addition to key auth.
- The add-member.sh or create-*.sh scripts are available.

## Recommended flow (one-liner style)

Use the unified protected entry point (sources `~/.config/tower/tower.env` or your protected location automatically):

```bash
cd ~/Developer/yousirjuan
scripts/fleet-claude member add avery dgx vps
```

Or the older direct calls (still supported):
```bash
cd ~/Developer/yousirjuan/ledger/LEDGER-0032-claude-ssh-user
bash playbooks/add-member.sh avery dgx vps
```

The script will:
- Source your local `operator-hosts.env`
- Pass the password (if any)
- Call the creator with full ACL flags (NOPASSWD sudo, AllowUsers, groups, etc.)

## Manual / per-target (if the wrapper doesn't cover your target yet)

Linux (DGX, VPS, NAS in some cases):

```bash
ssh admin@target \
  "sudo env USER_NAME=avery \
        PUBKEY='$(cat ~/.ssh/avery.pub)' \
        PASSWORD='$(grep ^CLAUDE_PASSWORD artifacts/operator-hosts.env | cut -d= -f2)' \
        NOPASSWD_SUDO=1 \
        bash -s" < playbooks/create-claude-user.sh
```

macOS targets:

Use `create-claude-user-mac.sh` directly on the target Mac (or via the remote provision path with bootstrap).

It now respects `PASSWORD=` if you export one.

## What ACL gets applied
- **SSH**: Public key in `~user/.ssh/authorized_keys`
- **Password** (optional): Set via chpasswd / sysadminctl
- **Sudo**: `/etc/sudoers.d/<user>` with NOPASSWD (configurable)
- **SSHD ACL**: Appended to restrictive `AllowUsers` drop-ins when present
- **Groups**: sudo/wheel/admin (Linux); access_ssh (macOS)
- **macOS specific**: Remote Login allowlist + sudoers

**Critical system rule:** Tailscale is banned everywhere (DGX, all Macs, VPS, routers, nephew deployments). Do not use Tailscale ACLs, Tailscale hostnames, or Tailscale for any member or fleet access. Use the family self-hosted WireGuard mesh (AllowedIPs, router firewall Trusted zones, Network Trust Spine / mTLS + WG). See `yousirjuan/rules/GLOBAL-RULES-FOR-USING-NEPHEW.md` (Core System Policy) and LEDGER-0018.

See `create-claude-user.sh` and `create-claude-user-mac.sh` for the exact logic.

## Updating operator-hosts.env for repeatability

Add entries like:

```env
# Member: avery
AVERY_PUBKEY_FILE=~/.ssh/avery.pub
# AVERY_PASSWORD=...   # only if different from CLAUDE_PASSWORD
AVERY_BOOTSTRAP=abrownsanta@avery-mac.local
```

Future versions of add-member.sh can loop over a `MEMBERS="avery bobby ..."` list.

## Verification

```bash
ssh avery@dgx-spark 'whoami && id && sudo -n true && echo "ACL OK (sudo without pw)"'
ssh avery@target 'ssh -T git@github.com'   # if they need git
```

## Revocation / removal

- Remove the line from `~user/.ssh/authorized_keys` on each host
- `sudo userdel -r user` (or just remove from AllowUsers / sudoers if you want to keep the home)
- For macOS: remove from com.apple.access_ssh group

## Related
- `playbooks/add-member.sh` (the wrapper)
- `README.md` (this ledger)
- `docs/family-fleet-ssh-claude.md` (public reference)
- `artifacts/operator-hosts.env` (your local secrets + member notes)
- LEDGER-0031 for device/mTLS member onboarding (separate from SSH accounts)
