# Runbook 01 — iMac prerequisites (operator-driven)

**Time:** ~15 minutes total (mostly waiting on download/sign-in)
**Reversible:** yes (uninstall OrbStack, sign out of Tailscale, restore Energy Saver defaults)
**Prereqs:** macOS Ventura+ (this iMac is 13.7.8), admin password for the operator account

## Why this can't be automated

Three changes that explicitly require the operator's hands:

1. **OrbStack install** — `brew install --cask orbstack` requires admin password to write `/Applications/OrbStack.app` (macOS guardrails on /Applications).
2. **Tailscale OAuth** — Tailscale.app opens a browser to the operator's identity provider (Google / Microsoft / etc.). The agent can't click through OAuth.
3. **Energy Saver toggles** — System Settings UI; `pmset` requires sudo and changes user-experience defaults the operator should consciously approve.

This runbook is the operator's checklist. After it's done, the install-standby.sh playbook does the rest non-interactively.

## Steps

### 1. Install OrbStack

```bash
brew install --cask orbstack
```

…or download from [orbstack.dev](https://orbstack.dev) and drag to /Applications.

Reasoning: OrbStack is significantly lighter than Docker Desktop on macOS, no commercial license issue, and provides drop-in `docker` and `docker compose` CLIs. The standby container uses ~1–2 GB RAM steady-state, ~2 GB disk for the GitLab image, plus the data volume.

After install, open OrbStack.app once so it can set up the helper. **Verify:** `docker version` returns a client + server version without error.

### 2. Re-authenticate Tailscale

Open Tailscale.app (already installed at `/Applications/Tailscale.app`). Click "Sign In." Authenticate via the same identity provider you used for the marvelousempire tailnet.

**Verify:**
```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
```
Should list `imac-avery` (or your iMac's tailnet name) as online with a `100.x.x.x` IP. If the hostname differs from `imac-avery` (e.g., the iMac was renamed), note the actual hostname — you'll edit the standby's `docker-compose.yml` external_url to match.

### 3. macOS Energy Saver — "always on" mode

Open **System Settings → Battery → Options** (on iMac, this may show as "Energy Saver" depending on macOS version).

Set:

| Setting | Value | Why |
|---|---|---|
| Prevent automatic sleeping when display is off | **ON** | Standby must keep accepting backup rsyncs even when display sleeps |
| Wake for network access | **ON** | If the standby ever sleeps and a remote tries to reach it, wake the machine |
| Start up automatically after a power failure | **ON** | Standby comes back without operator intervention after a power blip |
| Put hard disks to sleep when possible | **OFF** | GitLab data volume should stay spinning |

**Verify:**
```bash
pmset -g
```
Should show `displaysleep` non-zero (OK), `sleep 0`, `disksleep 0`, `womp 1` (wake on magic packet), `autorestart 1`.

### 4. Final operator-side verification

```bash
docker version | grep -E "Version|Server" | head -4 && \
/Applications/Tailscale.app/Contents/MacOS/Tailscale status | head -3 && \
pmset -g | grep -E "displaysleep|^ sleep|womp|autorestart"
```

If all three sections look healthy, prerequisites are met. Run the install playbook next:

```bash
bash ~/Developer/yousirjuan/ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh install
```

See [runbook 02](02-deploy-standby-container.md) for what happens next.

## Undo

```bash
# OrbStack:
brew uninstall --cask orbstack && rm -rf ~/.orbstack

# Tailscale: sign out from the app, or:
/Applications/Tailscale.app/Contents/MacOS/Tailscale logout

# Energy Saver: undo each toggle in System Settings (no CLI equivalent for the GUI defaults).
```

## Notes

- **OrbStack vs Docker Desktop** — both work. OrbStack is recommended because it boots faster, uses less RAM, and doesn't require a commercial license for personal use. If the operator prefers Docker Desktop, install that instead; the rest of the playbook is identical.
- **Tailscale Funnel** is the modern way to expose tailnet services to the public internet via Tailscale's edge. NOT enabled for this standby — the whole point of standby is that it's not public. If you want public access in the future (e.g., during a primary failover), enable Funnel separately.
- **Don't disable sleep on a Mac laptop** that's on battery — this runbook assumes a wired-power desktop (iMac). On a MacBook, the sleep-prevention would drain the battery quickly.
