---
ledgerId: LEDGER-0029
title: Domain migration yousirjuan.ai → jailynmarvin.com (dual-domain transition)
status: in-progress
opened: 2026-05-31
closed: null
related-pains: []
related-tickets: [LEDGER-0026, LEDGER-0028]
triggers: [manual]
---

# LEDGER-0029 — Domain migration to `jailynmarvin.com`

## Ask

Operator 2026-05-31:

> i want to change the domain TLD from yoursirjuan.app to jailynmarvin.com - i have already started making the A Records we need but i want you to give me all the DNS settings i need o set in the new domain so we have a clean merger.

Two domains for a transition window. Old (`yousirjuan.ai`) stays live alongside new (`jailynmarvin.com`) until every consumer (browser bookmarks, env vars, mobile apps, ssh aliases, certbot configs) has cut over. Nothing is forced off the old domain — it's deprecated, not killed.

## Architecture (post-migration steady state)

Two physical hosts, two IPs. Every record below resolves to one of them, and which one it points at is the whole architectural decision.

| Host | Public IP | Role | Reachable from |
|---|---|---|---|
| `clinic-vps` | `72.167.151.251` | GoDaddy datacenter; nginx multiplexer + public surface | Public internet |
| `DGX Spark` | `192.168.8.249` | Home LAN behind Verizon Business gateway; GPU work + private archive | LAN + family WireGuard mesh only |

### Public A records (→ `72.167.151.251`, clinic-vps via nginx)

| Record | Service | Container / process | Purpose |
|---|---|---|---|
| `jailynmarvin.com` (apex) | Landing | nginx static or redirect | Root site / 301 to apex content |
| `www.jailynmarvin.com` | Apex alias | nginx | Standard www→apex courtesy redirect |
| `nephew.jailynmarvin.com` | Nephew chat | nginx → tower-api `:8088` → hermes-bridge → DGX over WG | Public chat surface; CPU orchestration on VPS, GPU inference proxied to DGX (LEDGER-0026) |
| `clinic.jailynmarvin.com` | Clinic | nginx → clinic web app | Knowledge register UI |
| `git.jailynmarvin.com` | GitLab | nginx → gitlab container `:8929` | Self-hosted git mirror |
| `hello.jailynmarvin.com` | Hello placeholder | nginx static | "VPS is up" marker |
| `uptime.jailynmarvin.com` | Uptime Kuma | nginx → docker `:3011` | Status board |
| `workflow.jailynmarvin.com` | Workflow runner | nginx → workflow container | Automation engine |
| `acme-dns.jailynmarvin.com` | acme-dns server | docker `acme-dns` UDP/53 + nginx → `:8081` (API) | DNS challenge responder for the private archive (see LEDGER-0028) |

### Private A record (→ `192.168.8.249`, DGX, WG-only)

| Record | Service | Container / process | Purpose |
|---|---|---|---|
| `archive.jailynmarvin.com` | Search My Engine | Caddy on DGX → app:3000 | The operator-only archive (conversations / search / agent). Resolves in public DNS so the cert chain works, but the IP is private — off-mesh devices have no route. **Quiet-fail privacy property by design.** |

### Special records (cert delegation)

| Record | Type | Value | Purpose |
|---|---|---|---|
| `acme-dns.jailynmarvin.com` | NS | `acme-dns.jailynmarvin.com.` | Self-delegation. Makes the acme-dns container authoritative for `*.acme-dns.jailynmarvin.com`. Without this NS, Caddy can't solve DNS-01 challenges via acme-dns. |
| `_acme-challenge.archive.jailynmarvin.com` | CNAME | `<UUID>.acme-dns.jailynmarvin.com.` | Per-host cert challenge delegation. UUID is allocated when Caddy registers an acme-dns account for the new domain (separate from the existing `a05f4b61-…` UUID for `archive.yousirjuan.ai` — they're per-domain). |

### Nephew compute split (relevant context)

| Host | Containers | Why |
|---|---|---|
| `clinic-vps` | `nephew-postgres`, `nephew-redis`, `nephew-brain-db-1`, `tower-api` | Public chat surface needs to be world-reachable. CPU-only services live with the public ingress. |
| `DGX` | `nephew-embeddings`, `nephew-reranker`, `nephew-anthropic-shim`, `nephew-qdrant`, `~/Developer/nephew/` checkout | GPU-intensive inference + vectors live where the hardware is. tower-api on clinic-vps reaches these via the WG mesh (LEDGER-0026 `NEPHEW_HERMES_DIRECT_URL`). |

The split also applies to the new domain: `nephew.jailynmarvin.com` resolves to the **VPS** because that's where the public chat surface lives; the GPU work is invisible to DNS (internal WG hops only).

## Migration steps

### Phase 1 — DNS (operator, in GoDaddy panel)

✓ Apex A → 72.167.151.251
✓ www A → apex
✓ nephew, clinic, git, hello, uptime, workflow → 72.167.151.251
✓ acme-dns A → 72.167.151.251
⚠ **archive A → 192.168.8.249** (NOT the VPS IP — that's the privacy property)
⚠ **acme-dns NS → acme-dns.jailynmarvin.com.**
⚠ **_acme-challenge.archive CNAME → \<NEW-UUID>.acme-dns.jailynmarvin.com.** (UUID minted in Phase 2)

### Phase 2 — Server-side (operator approves, AI executes)

1. **Register new acme-dns account** for `archive.jailynmarvin.com` on clinic-vps's acme-dns API → returns a new UUID for the CNAME above.
2. **Add new domain to acme-dns config** `/opt/acme-dns/config.cfg` `records:` block so acme-dns answers for both `acme-dns.yousirjuan.ai` AND `acme-dns.jailynmarvin.com`.
3. **nginx site blocks** on clinic-vps — add `server_name jailynmarvin.com www.jailynmarvin.com;` (etc.) to each existing site config so both old + new hostnames are served. Run certbot for each new hostname.
4. **Caddy on DGX** — add `archive.jailynmarvin.com` site block alongside the existing `archive.yousirjuan.ai` block. Same `tls { dns acmedns … }` directive but with the new credentials JSON.
5. **AUTH_URL on DGX** — add `archive.jailynmarvin.com` to the trusted-host list so signin redirects work.

### Phase 3 — Client cutover

6. Update extension default endpoint hint to `https://archive.jailynmarvin.com/api/mirror`.
7. Update CLI default `ENGINE_URL` to `https://archive.jailynmarvin.com`.
8. Update iOS Shortcut doc example URL.
9. Mark `yousirjuan.ai` records "do not delete" for a defined window (e.g. 30 days) so any cached bookmark / mobile app / ssh alias still resolves.

### Phase 4 — Decommission (optional, end of transition window)

10. Remove `server_name yousirjuan.ai` from nginx configs.
11. Remove `archive.yousirjuan.ai` site block from Caddy.
12. Remove old DNS records from GoDaddy.
13. Update LEDGER-0028 + LEDGER-0029 status to `closed`.

## What's NOT migrating

- **Local docker compose project name** (`json-archive-chat-reader`) — pinned in compose.yml via `name:` so volumes don't orphan. Independent of any domain.
- **Postgres database name** (`claude_archive`) — internal; data lives there.
- **PAT prefix `ca_`** — would invalidate every existing token.
- **GitHub + GitLab repo slug** — already renamed to `search-my-engine` in a separate operation (pre-dates this ledger).

## Verification (end of Phase 3)

```bash
# From a wg-connected device:
curl -sIk https://archive.jailynmarvin.com/                 # HTTP/2 307 → /signin (real LE cert)
dig +short archive.jailynmarvin.com A                       # → 192.168.8.249
dig +short _acme-challenge.archive.jailynmarvin.com CNAME   # → <UUID>.acme-dns.jailynmarvin.com.

# From the public internet:
curl -sIk https://nephew.jailynmarvin.com/                  # HTTP 200 (or whatever the chat returns)
curl -sIk https://archive.jailynmarvin.com/                 # connection refused — quiet fail, no data exposure

# Old domain still works during transition:
curl -sIk https://archive.yousirjuan.ai/                    # still HTTP/2 307
```

## Related

- LEDGER-0026 — WG mesh that makes the private archive reachable
- LEDGER-0028 — self-hosted acme-dns (the piece that makes cert issuance work without GoDaddy API access)
- `marvelousempire/search-my-engine` (the renamed json-archive-chat-reader) — the consumer of `archive.jailynmarvin.com`
