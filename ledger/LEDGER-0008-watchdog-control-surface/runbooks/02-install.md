# Runbook 02 — Install the state server

## Prereqs

- LEDGER-0007 watchdog already installed (`launchctl list | grep com.yousirjuan.vps-watchdog`)
- `python3` available (`which python3` — macOS ships it)
- Tailscale running on the iMac (`tailscale status` shows the tailnet)

## Install

```bash
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh install && \
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh status
```

What this does:

1. Generates a bearer token at `~/.config/yousirjuan/watchdog-server.env` (only on first install)
2. Materializes the launchd plist at `~/Library/LaunchAgents/com.yousirjuan.watchdog-state-server.plist`
3. Loads it (`RunAtLoad=true` + `KeepAlive=true` — auto-starts and restarts on crash)
4. Probes `http://127.0.0.1:9876/health` to confirm it's up

## Capture the bearer token

The install script prints the token once. Capture it for DustPan settings:

```bash
cat ~/.config/yousirjuan/watchdog-server.env
# WATCHDOG_TOKEN=<base64url-string>
```

Paste this into the DustPan Watchdog settings panel's "Bearer token" field.

## Smoke test from the iMac

```bash
curl -s http://127.0.0.1:9876/health && \
curl -s http://127.0.0.1:9876/state | python3 -m json.tool | head -20 && \
curl -s http://127.0.0.1:9876/settings | python3 -m json.tool | head -20
```

Expected: `ok`, then the watchdog's current state JSON, then the seeded default config.

## Smoke test from the VPS (via Tailscale)

```bash
ssh vps-godaddy 'curl -s http://imac-avery:9876/health'
```

(`imac-avery` is the iMac's Tailscale hostname — adjust if yours differs.) Should print `ok`.

If this fails: confirm Tailscale ACL allows the VPS to reach the iMac on TCP 9876. See runbook 03.

## Uninstall

```bash
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh uninstall
```

Removes the plist + unloads the launchd job. The watchdog (LEDGER-0007) keeps running. The bearer token at `~/.config/yousirjuan/watchdog-server.env` is preserved — delete manually if rotating.

## Verification

After install, the Nephew Control Tower Overview page should show the WatchdogCard with live state within ~3 seconds of page load. DustPan's Settings page should show the Watchdog Settings panel populated with the current config.

If either shows "watchdog state unreachable," check:

1. `bash install-state-server.sh status` — is the server up?
2. `tailscale ping imac-avery` from the VPS or DustPan host
3. Tailscale ACL (runbook 03)
