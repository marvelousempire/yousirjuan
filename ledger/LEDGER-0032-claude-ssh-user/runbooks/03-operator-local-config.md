# 03 — Operator local config (gitignored)

## Why

The repo documents **patterns** with `192.168.x.y` placeholders. Hostnames,
usernames, IPv6 aliases, and VPS endpoints are **operator-private** and must not be
committed.

## Files

| File | Committed? | Purpose |
|---|---|---|
| `artifacts/operator-hosts.env.example` | yes | Template — copy and edit |
| `artifacts/operator-hosts.env` | **no** (gitignored) | Your real targets |
| `artifacts/ssh-config-snippet.example` | yes | Template for `~/.ssh/config` |
| `~/.ssh/config` | **no** | Merged aliases on your Mac |

## Setup

```bash
cd ~/Developer/yousirjuan
cp ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env.example \
   ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env
```

Edit `operator-hosts.env`:

- `VPS_SSH_HOST`, `VPS_SSH_USER`, `VPS_SSH_PORT`
- `DGX_SSH_HOST` (often an `/etc/hosts` IPv6 alias)
- `INNER_GW`, `UPSTREAM_GW`, `NAS_HOST`

Then append SSH aliases from `ssh-config-snippet.example` to `~/.ssh/config`, replacing
`your.vps.hostname.example` and `your-dgx-ipv6-alias`.

## Verify env is loaded

```bash
source ledger/LEDGER-0032-claude-ssh-user/artifacts/operator-hosts.env
echo "$VPS_SSH" "$AX1800_SSH"
```

`install-from-mac.sh` sources `operator-hosts.env` automatically when present.
