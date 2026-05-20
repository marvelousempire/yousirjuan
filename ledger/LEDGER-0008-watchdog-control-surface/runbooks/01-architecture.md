# Runbook 01 — Architecture

The state server is a thin HTTP read/write wrapper around the watchdog's existing JSON files. The watchdog itself remains the only writer of state and reader of config.

## Component map

```
   iMac (always on, LEDGER-0006 Energy Saver)
   ┌────────────────────────────────────────────────────────┐
   │  vps-watchdog.sh        (launchd, every 3 min)         │
   │     ├─ writes ~/Library/yousirjuan-state/vps-watchdog.json
   │     └─ reads  ~/Library/yousirjuan-state/vps-watchdog.conf
   │                                                        │
   │  watchdog-state-server  (launchd, KeepAlive)           │
   │     listens on 0.0.0.0:9876                            │
   │     ├─ GET  /state    → JSON state file               │
   │     ├─ GET  /logs     → last 200 lines of watchdog log │
   │     ├─ GET  /settings → JSON conf file                │
   │     ├─ POST /settings → atomic write to conf file      │
   │     │                   (requires Bearer token)        │
   │     └─ GET  /health   → "ok"                          │
   └────────────────────────────────────────────────────────┘
                              ▲
            Tailscale tailnet │ (ACL restricted, runbook 03)
                              ▼
   ┌──────────────────────────────────┬──────────────────────────────────┐
   │  Nephew Control Tower (VPS)      │  DustPan (Mac app + web)         │
   │    fetches /state /logs          │    fetches/posts /settings       │
   │    via VITE_WATCHDOG_URL         │    via local config              │
   └──────────────────────────────────┴──────────────────────────────────┘
```

## Endpoint spec

| Method | Path        | Auth      | Request          | Response             |
|--------|-------------|-----------|------------------|----------------------|
| GET    | `/health`   | none      | —                | `ok\n`               |
| GET    | `/state`    | none      | —                | `application/json` — current `vps-watchdog.json` |
| GET    | `/logs`     | none      | —                | `text/plain` — last 200 lines of watchdog log |
| GET    | `/settings` | none      | —                | `application/json` — current `vps-watchdog.conf` |
| POST   | `/settings` | Bearer    | JSON conf body   | `{"ok":true}` or 400/401 |

CORS is permissive on all endpoints (`Access-Control-Allow-Origin: *`) — safe because Tailscale ACL is the gate.

## Bearer token

Generated at install time, stored at `~/.config/yousirjuan/watchdog-server.env` (chmod 600). Format: `WATCHDOG_TOKEN=<base64url-32>`. POST requests must include `Authorization: Bearer <token>`.

GET endpoints are unauthenticated — they expose subdomain probe state (not secrets) and only to whoever can reach :9876, which is gated by Tailscale ACL.

## Settings schema (`vps-watchdog.conf`)

```json
{
  "dry_run": true,
  "domain": "yousirjuan.ai",
  "vps_ip": "72.167.151.251",
  "failover_ip": "",
  "targets": [
    {"sub": "hello",    "url": "https://hello.yousirjuan.ai/"},
    {"sub": "nephew",   "url": "https://nephew.yousirjuan.ai/"},
    {"sub": "clinic",   "url": "https://clinic.yousirjuan.ai/"},
    {"sub": "git",      "url": "https://git.yousirjuan.ai/"},
    {"sub": "workflow", "url": "https://workflow.yousirjuan.ai/"}
  ],
  "strikes_to_swap": 3,
  "strikes_to_revert": 3,
  "hysteresis_min_seconds": 1800,
  "probe_timeout_seconds": 10
}
```

The watchdog reads this file at the start of every tick (jq). DustPan POSTs to `/settings`, server writes atomically (`tmp` + rename), next watchdog tick (≤3 min) picks up the new config.

## Why the watchdog reads the conf file each tick instead of restarting

- **No service interruption** — settings change is a file write; no SIGHUP, no `launchctl unload/load`, no missed ticks.
- **Atomicity** — server writes to `vps-watchdog.conf.tmp` then renames. Watchdog never sees a half-written file.
- **Simpler revert** — operator can `git checkout` the conf file by hand if they edited it badly.

## Related

- [02-install.md](02-install.md) — operator install procedure.
- [03-tailscale-acl.md](03-tailscale-acl.md) — restrict :9876 to tailnet.
- [LEDGER-0007](../../LEDGER-0007-imac-emergency-failsafe/README.md) — the watchdog itself.
