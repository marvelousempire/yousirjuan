---
ledgerId: LEDGER-0007
title: iMac emergency failsafe for the VPS — 3-min watchdog + auto DNS swap
status: phase-1-shipped
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0006]
triggers:
  - launchd:every-3-min (~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist)
  - manual-cli: `bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh trigger`
phase-1:
  status: shipped
  date: 2026-05-20
  mode: DRY_RUN (no real DNS changes)
phase-2:
  status: deferred
  scope: standby containers for marketing + player-web + admin
phase-3:
  status: deferred
  scope: API standby + Postgres streaming replication + promotion
---

# LEDGER-0007 — iMac emergency failsafe for the VPS

## Ask

> "when the server at the VPS is down I want to be able to try to host the sites in the app for this computer […] every three minutes it'll check to see if VPS is back up so I can switch back over […] right now the server has been overloaded with pressure"

Direct observation in the same session: VPS load went from 10 → 42 → unreachable → reboot. Failover system is a real need, not a theoretical one.

## Outcome (Phase 1 shipped)

iMac runs a watchdog that probes the operator's VPS-hosted subdomains every 3 minutes. State machine: 3 consecutive failures → swap DNS to failover IP via GoDaddy API. 3 consecutive successes → revert. Per-subdomain hysteresis (≥30 min between swaps) prevents flapping.

**Ships in DRY_RUN mode** — the watchdog probes + logs decisions but does NOT call the GoDaddy API. Real swaps gated on:

1. Phase 2 standby containers being built (otherwise swapping DNS points traffic at nothing).
2. Operator providing GoDaddy API key + secret at `~/.config/yousirjuan/godaddy.env`.
3. Operator setting `FAILOVER_IP` at the top of `vps-watchdog.sh` (Tailscale Funnel public IP, or home WAN with port-forward).
4. Operator changing `DRY_RUN=1` → `DRY_RUN=0` in the script.

See [runbook 03 — enabling-real-swap](runbooks/03-enabling-real-swap.md) for the go-live procedure.

## Runbooks

- [01-godaddy-api-credentials.md](runbooks/01-godaddy-api-credentials.md) — operator obtains GoDaddy API key + secret from the GoDaddy Developer portal. Cannot be automated.
- [02-watchdog-design.md](runbooks/02-watchdog-design.md) — how the script works: state machine, hysteresis, probe semantics, decision logic.
- [03-enabling-real-swap.md](runbooks/03-enabling-real-swap.md) — checklist for flipping DRY_RUN=0 and going live.
- [04-vps-overload-triage.md](runbooks/04-vps-overload-triage.md) — when sshd hangs at banner exchange but the host is up: GoDaddy console + top + most-likely culprits (Cursor remote-server, GitLab Puma, OOM, disk-full).

## Playbooks

- [install-watchdog.sh](playbooks/install-watchdog.sh) — idempotent installer. Actions: install / uninstall / status / trigger / logs / help.
- [vps-watchdog.sh](playbooks/vps-watchdog.sh) — the watchdog itself. Run directly to test one tick; or via launchd every 3 min.
- [godaddy-dns.sh](playbooks/godaddy-dns.sh) — GoDaddy API helper. `get` and `set` actions. Reads creds from `~/.config/yousirjuan/godaddy.env`.

## Artifacts

- [com.yousirjuan.vps-watchdog.plist](artifacts/com.yousirjuan.vps-watchdog.plist) — LaunchAgent. `StartInterval=180` (every 3 min), `RunAtLoad=true`. Logs to `~/Library/Logs/yousirjuan-vps-watchdog.log`. State at `~/Library/yousirjuan-state/vps-watchdog.json`.

## Replay (zero-AI, on a fresh iMac)

```bash
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh install && \
bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh status
```

After install, watchdog runs every 3 min in DRY_RUN. Inspect log: `tail -f ~/Library/Logs/yousirjuan-vps-watchdog.log`.

## Verification

After install, after at least 2–3 ticks (~6–9 min):

```bash
bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh status
```

Should show: launchd job loaded, log entries with `── dry-run tick` + per-target `✓` or `✗` lines, JSON state file with non-zero `consecutive_successes` or `consecutive_fails`.

To test the swap-trigger logic without going live: edit `TARGETS=` at the top of `vps-watchdog.sh` to include a deliberately-broken URL (e.g., `https://nonexistent.yousirjuan.ai/`); after 3 ticks (~9 min), log should print `(dry-run) WOULD SWAP A record …`. Revert the change after observing.

## Undo

```bash
bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh uninstall
# state file preserved at ~/Library/yousirjuan-state/vps-watchdog.json
# delete manually if desired: rm -rf ~/Library/yousirjuan-state
```

## Today's smoke test results

Direct invocation of `vps-watchdog.sh` (DRY_RUN=1) from this iMac at 2026-05-20 07:36 ET:

| Subdomain | Probe result | Status |
|---|---|---|
| `hello.yousirjuan.ai` | ✓ HTTP 2xx/3xx/4xx | up |
| `nephew.yousirjuan.ai` | ✓ HTTP 2xx/3xx/4xx | up |
| `clinic.yousirjuan.ai` | ✓ HTTP 2xx/3xx/4xx | up |
| `git.yousirjuan.ai` | ✓ HTTP 2xx/3xx/4xx | up |
| `workflow.yousirjuan.ai` | ✗ HTTP 502 (n8n upstream dead) | down |

The 502 on workflow is **correctly classified as down** — n8n itself is failed, even though the VPS host is reachable. After 3 ticks of dry-run, the watchdog will log "WOULD SWAP A record workflow.yousirjuan.ai" — which it should NOT actually do in production because there's no n8n standby on the iMac yet. This is exactly why DRY_RUN is the default.

## Notes

- **The watchdog is the single point of failure for failover itself.** If the iMac is down, no failover triggers. Acceptable for v1; Phase 3+ could add a third site.
- **Hysteresis ≥ 30 min between swaps per subdomain** prevents flapping during repeated short outages. Tune `HYSTERESIS_MIN_SECONDS` in the watchdog if behavior needs to change.
- **TTL must be pre-lowered to 60s on each failover-eligible A record at GoDaddy.** Otherwise the swap takes up to 30 min to propagate. Documented in runbook 03.
- **DRY_RUN=1 is the default.** The first time the watchdog ever calls the GoDaddy API, that's an explicit operator decision. See runbook 03.

## Cross-references

- Builds on: [LEDGER-0006](../LEDGER-0006-gitlab-warm-standby/) — GitLab warm-standby. Same iMac-always-on prerequisites (Energy Saver, Tailscale).
- Future LEDGER-0008: API + Postgres streaming replication (Phase 3 of this work).
- Future Phase 2 (same ticket): standby containers for marketing + player-web + admin.
