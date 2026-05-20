---
ledgerId: LEDGER-0008
title: Watchdog control surface — state server + Nephew card + DustPan settings panel
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0007]
triggers:
  - launchd:run-at-load + keep-alive (~/Library/LaunchAgents/com.yousirjuan.watchdog-state-server.plist)
  - http-fetch:nephew-control-tower (GET /state /logs)
  - http-fetch:dustpan-settings-panel (GET /settings, POST /settings)
phase-1:
  status: in-this-pr
  scope: state server on iMac (yousirjuan repo) + vps-watchdog.sh conf-reload
phase-2:
  status: separate-PR
  scope: WatchdogCard + WatchdogStatusPage in marvelousempire/nephew
phase-3:
  status: separate-PR
  scope: WatchdogSettingsPanel in marvelousempire/dustpan
---

# LEDGER-0008 — Watchdog control surface

## Ask

> "watchdog needs to work inside of DustPan and Nephew Tower ok? Automatic on and needs great settings in the settings page too"

Make the LEDGER-0007 watchdog visible in Nephew Control Tower and controllable in DustPan, without the operator ever editing shell scripts.

## Outcome (Phase 1 shipped in this PR)

Tiny HTTP server (`watchdog-state-server`) runs on the iMac as a launchd job (`KeepAlive=true`, `RunAtLoad=true`). It exposes:

- `GET /state` — current watchdog JSON state
- `GET /logs` — last 200 lines of the watchdog log
- `GET /settings` — current config knobs
- `POST /settings` — atomic conf-file write (Bearer token required)
- `GET /health` — for the Nephew status card heartbeat

The watchdog (`vps-watchdog.sh`) is updated to read `~/Library/yousirjuan-state/vps-watchdog.conf` at the start of every tick, so settings POSTed from DustPan take effect within 3 min without any service restart.

Nephew Control Tower (`marvelousempire/nephew`) and DustPan (`marvelousempire/dustpan`) consume these endpoints in their own follow-up PRs (Phase 2 + Phase 3 of this ticket; tracked separately because they live in other repos).

## Runbooks

- [01-architecture.md](runbooks/01-architecture.md) — component map, endpoint spec, settings schema.
- [02-install.md](runbooks/02-install.md) — operator one-liner install, smoke test, uninstall.
- [03-tailscale-acl.md](runbooks/03-tailscale-acl.md) — restrict :9876 to tailnet, tag-based ACL.

## Playbooks

- [watchdog-state-server.sh](playbooks/watchdog-state-server.sh) — the Python http.server wrapper.
- [install-state-server.sh](playbooks/install-state-server.sh) — install/uninstall/status, idempotent.

## Artifacts

- [com.yousirjuan.watchdog-state-server.plist](artifacts/com.yousirjuan.watchdog-state-server.plist) — LaunchAgent. `RunAtLoad=true`, `KeepAlive=true`, `ThrottleInterval=10`.

## Replay (zero-AI)

```bash
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh install && \
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh status
```

## Verification

After install:

```bash
curl -s http://127.0.0.1:9876/health && \
curl -s http://127.0.0.1:9876/state | python3 -m json.tool | head -20 && \
curl -s http://127.0.0.1:9876/settings | python3 -m json.tool
```

Should print `ok`, the live watchdog state, then the (seeded) default config.

From the VPS via Tailscale: `ssh vps-godaddy 'curl -sf -m 3 http://imac-avery:9876/health'` → `ok`.

## Undo

```bash
bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh uninstall
```

Watchdog itself (LEDGER-0007) remains untouched. Bearer token at `~/.config/yousirjuan/watchdog-server.env` is preserved (delete manually if rotating).

## Cross-references

- Builds on: [LEDGER-0007](../LEDGER-0007-imac-emergency-failsafe/README.md) — the watchdog this surfaces.
- Builds on: [LEDGER-0006](../LEDGER-0006-gitlab-warm-standby/) — Tailscale tailnet (the network this rides on).
- Companion repos: `marvelousempire/nephew` (WatchdogCard PR), `marvelousempire/dustpan` (WatchdogSettingsPanel PR).
