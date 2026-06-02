Status: Phase 1 SHIPPED 2026-06-02 (config + generator proven, incl. the change-the-TLD test). Phases 2–6 pending.

# Plan 0004 — Domain-agnostic Framework: the TLD is one variable (SaaS-ready)

## Context

Operator 2026-06-02:

> the `*.yousirjuan.ai` family cassettes should all be `jailynmarvin.com` cassettes
> now — we phased out that TLD. In fact I should be able to **change that TLD anytime
> I want and nothing breaks**. Make it like that — this way I can **SaaS this entire
> app and Framework**.

Today the TLD is hardcoded in ~24+ places in this repo (plus the live edge configs,
each cassette app, DNS, and certs). Goal: the TLD lives in **one source of truth**;
every cassette URL, edge vhost, DNS record, cert, mTLS, and SSO setting is **derived**
from it. Flip the value → regenerate → everything follows. That's the foundation for
**multi-tenant SaaS**: one config file per customer TLD, zero hardcoding.

## Design — one config, everything generated

### 1. Single source of truth — `framework.config.json`
```json
{
  "tld": "jailynmarvin.com",
  "org": "Jailyn Marvin Family Office",
  "edge_ip": "72.167.151.251",
  "cassettes": {
    "nephew":  { "tier": "mtls", "upstream": "127.0.0.1:8000" },
    "search":  { "tier": "mtls", "upstream": "192.168.8.249:443", "ssl_proxy": true },
    "bank":    { "tier": "mtls", "upstream": "192.168.8.249:3010" },
    "clinic":  { "tier": "public", "upstream": "127.0.0.1:5436" },
    "portainer": { "tier": "wireguard" },
    "vault":     { "tier": "wireguard" }
  }
}
```
Changing `tld` is the only edit needed. `tier` decides exposure (mtls · public · wireguard-only).

### 2. Generation layer — `scripts/render-framework.sh`
Reads the config and emits, all keyed off `${name}.${tld}`:
- **Edge vhosts** (nginx today; Caddy later) — one server block per cassette → its upstream, with the mTLS gate auto-added for `tier: mtls`, and *no public vhost* for `tier: wireguard`.
- **DNS record set** — `edge` A → `edge_ip`; one `CNAME ${name} → edge` per non-wireguard cassette (paste-ready for the provider).
- **Cert manifest** — the SAN list / wildcard for the active TLD.
- **Per-app env** — `PUBLIC_HOST=${name}.${tld}` injected into each cassette's runtime.

### 3. App-side — no hardcoded domains
Each app reads its host from env (`PUBLIC_HOST` / `FRAMEWORK_TLD`), never a literal.
Sweep: Nephew page map, SSO `return`/cookie-domain, the Nephew agent's URLs, the
search-my-engine cassette config, etc.

### 4. mTLS CA + cron — parameterize by org/TLD
`family-ca.sh` and the endpoint-heal cron take the TLD/org from the config.

## Tasks (phased — each shippable + reversible)

1. **Phase 1 — config + edge renderer.** Add `framework.config.json` (current state) +
   `render-framework.sh` that regenerates the **current jailynmarvin nginx vhosts
   byte-identically** (prove the generator before trusting it). No live change yet.
2. **Phase 2 — flip the live edge to generated.** Replace the hand-written
   `*.jailynmarvin.com` vhosts with generated ones (reversible: keep backups). This is
   where `yousirjuan.ai → jailynmarvin.com` lands cleanly — old names just disappear
   from the config.
3. **Phase 3 — DNS + cert generation** from the config (output the record set + SAN list).
4. **Phase 4 — app-side sweep.** Replace hardcoded domains in each cassette app with the
   env var. Per-repo PRs.
5. **Phase 5 — the flip test.** Change `tld` to a throwaway domain in a staging config,
   regenerate, confirm a full edge + DNS + cert set comes out correct → proves
   "change the TLD, nothing breaks."
6. **Phase 6 — SaaS.** One `framework.config.json` per tenant; `render-framework.sh
   --tenant <id>` stands up a fresh isolated instance.

## Critical files
| Path | Change |
|---|---|
| `framework.config.json` (new) | single source of truth: tld, org, edge_ip, cassettes |
| `scripts/render-framework.sh` (new) | renders edge vhosts / DNS / cert manifest / app env |
| live VPS nginx vhosts | replaced by generated output (Phase 2) |
| each cassette app config | domain → env var (Phase 4) |
| `ledger/LEDGER-0031/playbooks/family-ca.sh` | org/TLD from config |

## Verification
1. Phase 1: `render-framework.sh` output `diff`s clean against the current live
   `*.jailynmarvin.com` nginx vhosts (byte-identical).
2. Phase 5: set `tld: example-test.com`, render → every cassette appears as
   `*.example-test.com` across vhosts + DNS + cert manifest, with correct tiers.
3. search/nephew/bank still serve + stay mTLS-gated after the Phase-2 flip.

## Out of scope
- Per-tenant data isolation (that's the SaaS DB-split track, search-my-engine Plan 0037).
- Migrating the *other businesses'* domains (readyplay/averyhandyman/etc.) — they're
  separate public sites, not Framework cassettes.
