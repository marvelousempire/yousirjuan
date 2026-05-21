---
ledgerId: LEDGER-0016
title: Uptime Kuma — external uptime monitoring + multi-channel alerts (Telegram / email / Pushover)
status: in-progress
opened: 2026-05-21
closed: null
related-tickets: [LEDGER-0007, LEDGER-0010, LEDGER-0011, LEDGER-0012, LEDGER-0013, LEDGER-0015]
triggers:
  - docker-compose:uptime-kuma container (KeepAlive=true, restart=unless-stopped)
  - http:GET https://uptime.yousirjuan.ai/
---

# LEDGER-0016 — Uptime Kuma monitoring

## Ask

Operator 2026-05-21, referencing external recommendation: *"Uptime Kuma — Excellent for monitoring if your API endpoints are up. Pings your FastAPI health check every 20–60 seconds and can send you notifications via Telegram, Discord, email, etc. […] set up Uptime Kuma […] in the Control Tower."*

The existing stack covers:
- LEDGER-0012 `/sites` — per-VPS health probe of yousirjuan.ai subdomains, exposed in Nephew + DustPan
- LEDGER-0015 `alert-watch` — macOS notifications when thresholds cross

What's missing: **external uptime monitoring that reaches your phone** when the Mac isn't open, with status page, multi-channel notifications, and historical uptime stats (SLA-style).

## Outcome

Standalone Uptime Kuma container on the VPS at `uptime.yousirjuan.ai`. Lightweight (~50 MB steady-state), memory-capped at 256 MB per ADR-0001 (selective Docker for the unruly).

## Playbooks

- [install.sh](playbooks/install.sh) — install/uninstall/status on VPS. Idempotent.

## Artifacts

- [docker-compose.yml](artifacts/docker-compose.yml) — bind 127.0.0.1:3011, mem 256M, persistent volume at `/var/lib/yousirjuan/uptime-kuma`
- [uptime.yousirjuan.ai](artifacts/uptime.yousirjuan.ai) — nginx vhost (TLS + WebSocket upgrade headers)

## Runbooks

- [01-recommended-monitors.md](runbooks/01-recommended-monitors.md) — seed list (6 public subdomains + 3 Tailscale-internal /health endpoints) + notification channels + public status page setup

## Replay

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0016-uptime-kuma-monitoring/playbooks/install.sh install'
```

Then operator follow-ups:
1. Add A record `uptime.yousirjuan.ai → 72.167.151.251` in GoDaddy DNS
2. `sudo certbot --nginx -d uptime.yousirjuan.ai`
3. Open `https://uptime.yousirjuan.ai/`, complete admin setup, add monitors per runbook 01

## Verification

```bash
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0016-uptime-kuma-monitoring/playbooks/install.sh status'
# Local: HTTP 200, Public: HTTP 200 (after DNS + certbot)
```

## Undo

```bash
ssh vps-godaddy 'sudo bash ledger/LEDGER-0016-uptime-kuma-monitoring/playbooks/install.sh uninstall'
```

Data preserved at `/var/lib/yousirjuan/uptime-kuma/` (delete manually if rotating).

## How this fits the other monitoring layers

| Layer | What | Range |
|---|---|---|
| **LEDGER-0007 watchdog** (iMac) | DNS failover decision-maker on 3-strike rule | VPS subdomain HTTP probes |
| **LEDGER-0012 agent** (VPS) | Live /system /processes /entities /sites for UI consumption | VPS host state |
| **LEDGER-0015 server-tamer** (VPS) | Proactive killer at 92% mem sustained | VPS process state |
| **LEDGER-0015 alert-watch** (iMac) | macOS notifications when thresholds cross | iMac-side push |
| **LEDGER-0016 Uptime Kuma** (VPS, this) | External uptime monitoring + multi-channel alerts + status page | Multi-channel push (Telegram/email/Pushover) + public status page |

Triangulation: when Uptime Kuma alerts AND LEDGER-0012 /sites shows clean → network/TLS issue, not service. When both alert → real outage. When server-tamer kills + Uptime Kuma stays clean → kill was the right call (prevented an outage you would have seen otherwise).

## Phase 2 (separate PR — nephew)

Add an "Uptime" tile in Nephew Control Tower OverviewPage that iframes the public Uptime Kuma status page at `https://uptime.yousirjuan.ai/status/yousirjuan`. ~20 lines of TSX.

## Phase 3 (separate PR — dustpan)

Add `/operator-intent`, `/tamer-state`, `/history` endpoints to the LEDGER-0012 agent + corresponding DustPan UI surfaces so the operator sees the full server-tamer state + alert-watch state + 24h memory chart inside DustPan, complementing what Uptime Kuma shows.

## Why this is NOT shoehorned into LEDGER-0010 sandbox generator

LEDGER-0010 is for **CLIs** (interactive shells in containers). Uptime Kuma is a long-running web service with persistent state + ports. Different shape; deserves its own setup. Still follows ADR-0001 (selective Docker + memory cap + dedicated workspace).

## Cross-references

- LEDGER-0007 — watchdog (parallel uptime decision-maker; complementary)
- LEDGER-0010 — sandbox generator (similar pattern, different use case)
- LEDGER-0012 — VPS agent (Uptime Kuma's /health monitor for the agent itself)
- LEDGER-0013 — wire-marvelous-app + nginx vhost pattern (same vhost template family)
- LEDGER-0015 — alert-watch + server-tamer (the active defense layer; Uptime Kuma is the external observation layer)
