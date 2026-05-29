# 09 — Verify End-to-End

## Why

After every fresh bootstrap (or whenever anyone wonders "is the chat alive right now"), this runbook walks the full stack.

## The 8-gate smoke test

Run from the operator's Mac:

```bash
bash ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/verify-end-to-end.sh
```

That script checks every gate in order:

| # | Gate | Pass criteria |
|---|---|---|
| 1 | VPS WG handshake | `latest handshake < 60s` on `wg show wg0` |
| 2 | VPS → DGX ping over WG | 3 packets received, RTT < 200ms |
| 3 | VPS → DGX hermes `/v1/models` | JSON with at least one model |
| 4 | VPS tower-api `/api/agents/nephew-chat/status` (local) | `ok:true, api:connected, tunnel:direct-url` |
| 5 | `nephew.yousirjuan.ai` HTTPS | 200, valid TLS, certbot expiry > 14 days |
| 6 | Production `/api/agents/nephew-chat/status` | `ok:true, api:connected` |
| 7 | `/chat` HTML renders | 200, has the React shell |
| 8 | DGX hermes container | `docker ps` shows `hermes: Up <duration>` |

Expected output:

```
[1/8] VPS WG handshake               ... ok (latest 12s)
[2/8] VPS → DGX ping over WG         ... ok (78ms avg)
[3/8] VPS → DGX hermes /v1/models     ... ok (hermes-agent listed)
[4/8] VPS tower-api local /status    ... ok (tunnel: direct-url)
[5/8] nephew.yousirjuan.ai HTTPS     ... ok (valid until 2026-08-27)
[6/8] production /api/agents/.../status ... ok
[7/8] /chat renders                   ... ok
[8/8] DGX hermes container up         ... ok (Up 2 hours)

✅ Family AI stack is live.
```

## Manual sanity checks

1. Browser at `https://nephew.yousirjuan.ai/chat` — HealthPill at top right is GREEN.
2. Send a message like "Hi Nephew, who are you?". Tokens stream in within 2 seconds. Footer shows timing + model.
3. Open the iMessage thread — send a message there. Reply arrives via Mac SSH tunnel.
4. On iPhone with WG VPN ON, browse to `https://nephew.yousirjuan.ai/chat`. Same green pill, same streaming.

## When a gate fails

| Failed gate | Most likely cause | Refer to runbook |
|---|---|---|
| 1 | Verizon port-forward / GL-MT6000 firewall lost rules | 03, 06 |
| 2 | GL-MT6000 FORWARD rules missing OR DGX cable wrong port | 03, 04 |
| 3 | DGX hermes container down / IP changed | 04 |
| 4 | tower-api env var missing | 08 |
| 5 | TLS cert expired | 02 (certbot renew) |
| 6 | nginx `/api/agents/` location block missing | 07 |
| 7 | Static build failure or wrong dist path | 07 |
| 8 | docker daemon down / hermes crashed | 04 |

## Undo

Verification is read-only. Nothing to undo.
