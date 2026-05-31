---
ledgerId: LEDGER-0030
title: Add Nephew tower-api + control-tower to the DGX (parallel to clinic-vps)
status: proposed
opened: 2026-05-31
closed: null
related-pains: []
related-tickets: [LEDGER-0026, LEDGER-0029]
triggers: [manual]
---

# LEDGER-0030 — tower-api + control-tower on DGX (proposed)

## Ask

Operator 2026-05-31, after I listed the DGX nephew GPU services:

> Add tower-api + control-tower on DGX too (so chat works without clinic-vps)

The intent: chat with Nephew directly on the DGX (over WG) when wg is on, without bouncing through the public clinic-vps surface. Removes the only public-internet hop in the chat path. Useful for redundancy and as a backstop if clinic-vps is down.

## Discovery — what's currently where

**clinic-vps (`72.167.151.251`, public via nginx):**
- `bishop-tower.service` — BFF for control-tower UI
- `n8n-nephew.service` — n8n workflow UI (private/family-only on this host)
- `nephew-agent.service` — autonomous Nephew agent loop
- `nephew-meta-library-sync-watcher.service` — downstream sync watcher
- `nephew-tower-nginx.service` — static control-tower UI server
- Plus containers: `nephew-postgres`, `nephew-redis`, `nephew-brain-db-1`
- All under `/opt/nephew/` (systemd-managed, not docker-compose)
- Public entry point: `https://nephew.jailynmarvin.com/` → nginx → tower-api `:8088`

**DGX (`192.168.8.249`, WG-only):**
- `nephew-embeddings` (`:9200`)
- `nephew-reranker` (`:9201`)
- `nephew-anthropic-shim` (`:8910`)
- `nephew-qdrant` (`:6333-6334`)
- All under `~/Developer/nephew/`, managed by `docker-compose.dgx.yml` (project: `nephew-fleet`)
- No public surface; consumed by clinic-vps tower-api via WG (LEDGER-0026 `NEPHEW_HERMES_DIRECT_URL`).

## Scope of "add tower-api + control-tower on DGX"

This is **larger than a single session** if done properly. Honest inventory:

### Must reproduce on DGX

1. **`tower-api`** itself — source at `~/Developer/nephew/src/tower-api/`. Need to:
   - Determine language / runtime (Node? Python?) — `src/tower-api/` has not been inspected for build artifacts yet
   - Either containerize it OR install as a systemd service on DGX
   - Env vars: `ANTHROPIC_API_KEY`, `NEPHEW_HERMES_DIRECT_URL` (loopback now since both sides are local), DB URLs, auth secrets, marketplace catalog path, etc.
2. **`nephew-postgres`** — schema + data. Either replicate from clinic-vps, or run empty and let tower-api migrate fresh.
3. **`nephew-redis`** — session/cache store. Empty start is fine.
4. **`nephew-brain-db`** — Postgres for Nephew's memory.
5. **`bishop-tower.service`** — Express BFF. Source somewhere in `marvelousempire/nephew`.
6. **`nephew-tower-nginx.service`** — static UI server for `apps/control-tower/dist/`. Easy.
7. **`nephew-meta-library-sync-watcher.service`** — possibly skip on DGX; sync is one-way from clinic-vps "upstream" node. Operator's call.
8. **`nephew-agent.service`** — the autonomous agent. Optional; could run on either or both.

### Net-new on DGX

9. **Caddy site block** for `nephew-local.jailynmarvin.com` (or whatever hostname; can't reuse `nephew.jailynmarvin.com` since that's public and already on clinic-vps)
10. **DNS A record** `nephew-local.jailynmarvin.com → 192.168.8.249` (same WG-only pattern as `archive.jailynmarvin.com`)
11. **New acme-dns UUID + CNAME** `_acme-challenge.nephew-local.jailynmarvin.com → <UUID>.acme-dns.jailynmarvin.com.`
12. **Decision: data sharing.** Do DGX-side chats sync to clinic-vps nephew-postgres? Or are they independent? Two separate stores means split history; replication means more moving parts. Operator's call.

### Estimate

Conservatively **~1 week of careful work** if every system has to be re-deployed cleanly with proper config management. Could be ~2-3 hours of "hacky local dev" if the goal is just "I want to send Nephew a message from my iPad on the WG mesh and get a reply" with no production-grade replication / migration.

## Decision needed from operator

| Path | Effort | What you get |
|---|---|---|
| **A — Minimal viable DGX chat** | ~3h | Tower-api runs on DGX as a single docker service (containerise from source). Talks to a fresh nephew-postgres on DGX. No marketplace, no n8n, no agent loop. Chats are isolated — not synced to clinic-vps. Reachable at `https://nephew-local.jailynmarvin.com/` over WG. |
| **B — Full parity with clinic-vps** | ~1 week | All 5 systemd services replicated on DGX, postgres replication set up between the two nephew-postgres instances, n8n + agent loops running on DGX too, marketplace catalog mirrored. Production-grade redundancy. |
| **C — Hybrid: DGX chat surface, clinic-vps remains source of truth** | ~1 day | Tower-api on DGX is a "thin client" that proxies through to the existing clinic-vps tower-api over WG. Operator gets the latency benefit of local-network DNS + a private chat URL, but the actual state still lives on clinic-vps. Lowest data-divergence risk. |

**Recommendation: C.** Keeps clinic-vps as the canonical chat store (matches the existing nephew.jailynmarvin.com behaviour). DGX gets a private URL for "chat from my wg-only device without touching the public surface." If clinic-vps goes down, the chat surface on the DGX would also fail — but that's the same blast radius as today, just with no public exposure.

## Out of scope

- Migrating clinic-vps data to DGX or vice versa — separate operation if ever needed.
- Decoupling Nephew from the systemd model on clinic-vps — that's a refactor for clinic-vps, not part of this ledger.
- iOS / mobile native Nephew clients — they hit the same HTTPS surface regardless of where it lives.

## Verification (whichever path is taken)

```bash
# From any WG-connected device:
curl -sIk https://nephew-local.jailynmarvin.com/                   # HTTP 200 / 307
curl -sk https://nephew-local.jailynmarvin.com/api/v1/health       # tower-api healthy

# Chat round-trip via existing Nephew CLI / iOS client / web UI.
```

## Related

- LEDGER-0026 — WG mesh that makes DGX reachable from peers
- LEDGER-0028 — acme-dns server that issues the cert
- LEDGER-0029 — domain migration to jailynmarvin.com (provides the new hostname)
