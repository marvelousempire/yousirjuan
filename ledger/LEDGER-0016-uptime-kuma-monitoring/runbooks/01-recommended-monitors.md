# Runbook 01 — Recommended Uptime Kuma monitor seed list

After first-time setup of Uptime Kuma (admin password, your name, email), add these monitors. All are HTTPS pings every 60s with notifications enabled.

## Subdomain endpoints (your public surfaces)

| Name | Type | URL | Interval |
|---|---|---|---|
| hello.yousirjuan.ai | HTTP(s) | https://hello.yousirjuan.ai/ | 60s |
| nephew.yousirjuan.ai | HTTP(s) | https://nephew.yousirjuan.ai/ | 60s |
| clinic.yousirjuan.ai | HTTP(s) | https://clinic.yousirjuan.ai/ | 60s |
| git.yousirjuan.ai | HTTP(s) | https://git.yousirjuan.ai/ | 60s |
| workflow.yousirjuan.ai | HTTP(s) | https://workflow.yousirjuan.ai/ | 60s |
| uptime.yousirjuan.ai (self) | HTTP(s) | https://uptime.yousirjuan.ai/ | 120s |

## Infrastructure endpoints (Tailscale-internal)

| Name | Type | Target |
|---|---|---|
| VPS Agent /health | HTTP(s) | http://vps-godaddy:9878/health |
| iMac State Server /health | HTTP(s) | http://imac-avery:9876/health |
| iMac Tamer Server /health | HTTP(s) | http://imac-avery:9877/health |

## Notification channels to configure

Settings → Notifications:

1. **Telegram** — fastest pings, works on watch/phone/desktop
2. **Email (SMTP)** — for non-urgent / digest
3. **Webhook → Pushover** — if you want iPhone push notifications
4. **Webhook → DustPan** — future: post to DustPan's notification ingest endpoint when one exists (Phase 4)

## Status page (public read-only)

Settings → Status Pages → New:

- **URL slug:** `yousirjuan`
- **Show monitor list:** yes
- **Optional incident log:** yes

Result: `https://uptime.yousirjuan.ai/status/yousirjuan` — a public dashboard you can share or embed.

## How this complements the rest of the stack

| Layer | What it does | What Uptime Kuma adds |
|---|---|---|
| LEDGER-0007 watchdog | Decides DNS failover (DRY_RUN) | Independent confirmation of UP/DOWN; external view |
| LEDGER-0012 agent /sites | Probes from the VPS itself (internal) | Probes from the VPS too, BUT also can be hit externally → shows network-layer issues |
| LEDGER-0015 alert-watch | macOS notifications when thresholds cross | Telegram/email/Pushover — reaches you when not at the Mac |

The three layers + Uptime Kuma triangulate. If only Uptime Kuma fires but the LEDGER-0012 sites endpoint is clean → it's a network/TLS issue, not a service issue. If both fire → real outage.
