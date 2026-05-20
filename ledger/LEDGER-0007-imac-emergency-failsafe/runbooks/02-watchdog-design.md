# Runbook 02 — Watchdog design

How `vps-watchdog.sh` works under the hood. Read this before changing the script.

## Architecture

```
   launchd (StartInterval=180s)
              │
              ▼
   ┌──────────────────────────────────────────────────────────────┐
   │  vps-watchdog.sh   — one tick                                │
   │                                                              │
   │  for each (subdomain, probe-url) in TARGETS:                 │
   │    code = curl --max-time 10 probe-url                       │
   │    UP if code ∈ {2xx, 3xx, 4xx}                              │
   │    DOWN if code = 000 (connect fail) OR 5xx                  │
   │                                                              │
   │    update counters in ~/Library/yousirjuan-state/…json       │
   │    if status=vps and fails ≥ 3:                              │
   │      decision = SWAP_TO_FAILOVER                             │
   │    if status=failover and successes ≥ 3:                     │
   │      decision = REVERT_TO_VPS                                │
   │                                                              │
   │    apply hysteresis: skip if last swap < 30 min ago          │
   │                                                              │
   │    if DRY_RUN=1: log "WOULD …", don't call GoDaddy           │
   │    else:        godaddy-dns.sh set … 60                      │
   │                                                              │
   │  emit "── tick complete"                                     │
   └──────────────────────────────────────────────────────────────┘
              │
              ▼
   logs to ~/Library/Logs/yousirjuan-vps-watchdog.log
```

## Probe semantics

| HTTP code from `curl --max-time 10` | Classification |
|---|---|
| 200, 204, 301, 302, 401, 403, 404 | **UP** — server alive, responding |
| 500, 502, 503, 504 | **DOWN** — server upstream failure |
| 000 (curl exit) | **DOWN** — DNS/network/timeout |

Rationale: failover should fire when the VPS is genuinely unhealthy, not when a single app behind nginx happens to require authentication. A 401 from `workflow.yousirjuan.ai` (n8n basic auth) is "site is fine, you can't log in" — not "VPS is down."

## State machine per subdomain

Each subdomain has its own independent state. Initial state for everything: `vps` (canonical state, A record points at VPS).

```
                ┌───────────┐
                │  status:  │
                │   vps     │◀─────────────┐
                └─────┬─────┘              │
                      │                    │ 3 consecutive
       3 consecutive  │                    │ successes
       fails          │                    │ post-swap
                      ▼                    │
                ┌───────────┐              │
                │  status:  │──────────────┘
                │ failover  │
                └───────────┘
```

The status field lives in the state JSON. Counters reset to 0 on each transition.

## State file shape

`~/Library/yousirjuan-state/vps-watchdog.json`:

```json
{
  "targets": {
    "hello": {
      "status": "vps",
      "consecutive_fails": "0",
      "consecutive_successes": "4",
      "last_tick_epoch": "1779277005",
      "last_swap_epoch": "0"
    },
    "workflow": {
      "status": "vps",
      "consecutive_fails": "5",
      "consecutive_successes": "0",
      "last_tick_epoch": "1779277005",
      "last_swap_epoch": "0",
      "would_be_status": "failover"
    }
  }
}
```

Fields:

- `status` — current authoritative state for this subdomain. `vps` or `failover`.
- `consecutive_fails` / `consecutive_successes` — counters; mutually exclusive (only one is non-zero at a time per tick).
- `last_tick_epoch` — when this subdomain was last probed.
- `last_swap_epoch` — when the DNS was last actually swapped (or `0` if never).
- `would_be_status` — present in DRY_RUN mode only; says what state we'd transition to if real.

## Hysteresis

`HYSTERESIS_MIN_SECONDS=1800` (30 min) — minimum elapsed time between consecutive DNS swaps for the same subdomain. Without this, a flaky VPS could flap between vps↔failover several times an hour, each swap costing one GoDaddy API call + a propagation window for clients.

If the watchdog wants to swap but hysteresis blocks it, it logs `[hysteresis] $sub last swap ${elapsed}s ago < ${HYSTERESIS_MIN_SECONDS}s; deferring`.

## Configuration knobs (top of vps-watchdog.sh)

| Variable | Default | Meaning |
|---|---|---|
| `DRY_RUN` | `1` | If 1, watchdog probes + logs but never calls GoDaddy. |
| `DOMAIN` | `yousirjuan.ai` | The registered domain in GoDaddy. |
| `VPS_IP` | `72.167.151.251` | A-record value for "primary." |
| `FAILOVER_IP` | `(empty)` | A-record value for "failover." Must be set before going live. |
| `TARGETS` | array | List of `"subdomain\|probe-url"` pairs to monitor. |
| `STRIKES_TO_SWAP` | `3` | Consecutive fails before swap. |
| `STRIKES_TO_REVERT` | `3` | Consecutive successes (post-swap) before revert. |
| `HYSTERESIS_MIN_SECONDS` | `1800` | Min seconds between swaps per sub. |
| `PROBE_TIMEOUT` | `10` | Per-probe curl timeout in seconds. |

## When the watchdog is unsafe to use

- **FAILOVER_IP not set + DRY_RUN=0** — the script refuses to start. It would otherwise point a subdomain at nothing.
- **GoDaddy creds missing + DRY_RUN=0** — the API helper errors; watchdog logs failure and skips the swap; will retry next tick.
- **TARGETS includes a subdomain that has no failover destination** (e.g., n8n with no n8n standby) — the watchdog will swap DNS but the new IP serves nothing for that subdomain. Operator's responsibility to keep TARGETS aligned with what actually has a standby.

## Observability

- **Log**: `tail -f ~/Library/Logs/yousirjuan-vps-watchdog.log`. One entry per tick + per-target lines.
- **State**: `cat ~/Library/yousirjuan-state/vps-watchdog.json | python3 -m json.tool`.
- **`install-watchdog.sh status`** combines both for one-shot inspection.

## Related

- [01-godaddy-api-credentials.md](01-godaddy-api-credentials.md) — credentials for the live mode.
- [03-enabling-real-swap.md](03-enabling-real-swap.md) — go-live checklist.
