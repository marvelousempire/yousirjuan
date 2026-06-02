# Edge Architecture — Triple-Threat (target) + phased rollout

> **Status:** target architecture adopted 2026-06-02 · **Helm:** Caddy
> **Companion:** [`cassette-subdomain-edge-architecture.md`](cassette-subdomain-edge-architecture.md) ·
> [`dns-jailynmarvin-zone-2026-06-02.md`](dns-jailynmarvin-zone-2026-06-02.md) ·
> ledger [`LEDGER-0031`](../ledger/LEDGER-0031-cassette-edge-mtls-wireguard/)

Each proxy plays only its strongest hand. **Caddy is the permanent helm** (the
bulk); nginx and Traefik are specialized layers switched on only when their
strength becomes a real need. Layered in series, not competing.

```
                          PUBLIC INTERNET
                                │
   LAYER 1  ┌─────────────────▼──────────────────┐  Phase 3 — only for a public
   nginx    │  nginx + WAF — "the public moat"     │  regulated tier (marketing /
   +WAF     │  ModSecurity/Coraza · rate-limit ·   │  public SaaS). Scrubs, limits,
            │  bot/DDoS absorb → forwards clean    │  blocks; forwards inward.
            └─────────────────┬──────────────────┘
                                │ (private hop)
   LAYER 2  ┌─────────────────▼──────────────────┐  Phase 1 — NOW. Runs on VPS +
   Caddy    │  Caddy — "the helm" (THE BULK)       │  DGX (failover). Identity edge:
   HELM ◄───│  mTLS device-cert gate · family SSO  │  "trusted family device?" +
            │  handoff · wildcard DNS-01 · Host-    │  "which member?". Routes every
            │  routing every cassette · default-deny│  cassette.
            └─────────────────┬──────────────────┘
                  ┌────────────┴────────────┐
                  ▼                          ▼
          stable cassette              ┌──────────────┐  Phase 2 — when containers
          backends                     │  Traefik     │  go dynamic/multi-tenant
          (nephew, search,             │  dispatcher  │  (Plan 0037 SaaS split).
          bank, clinic, …)             └──────────────┘  Auto-discovers Docker
                                         containers via labels — per-tenant /
                                         ephemeral / preview envs, no reconfig.
```

## Who owns what — and why it's that one

| Layer | Tool | Strongest hand | Owns |
|---|---|---|---|
| Public moat | **nginx + WAF** | hardened public exposure, mature WAF, raw RPS | the only thing the open internet touches on a *public* tier |
| **Helm (bulk)** | **Caddy** | secure defaults, trivial mTLS, native wildcard DNS-01, replicable one-file config | identity/mTLS/SSO edge + Host-routing for every cassette, VPS + DGX |
| Dispatcher | **Traefik** | dynamic container discovery (labels, no reload) | fan-out to live app/tenant containers behind Caddy |

**Defense-in-depth bonus:** three independent codebases in series (content WAF →
identity gate → topology dispatch). A 0-day in one is not a 0-day in all — vendor
diversity is itself a control.

## Phased rollout (each layer earns its keep)

| Phase | Trigger | Action | Status |
|---|---|---|---|
| **1** | now | **Caddy at the helm** — mTLS + wildcard DNS-01 + cassette routing on VPS + DGX. Migrate the VPS edge off nginx via reversible parallel-port cutover. | **building — LEDGER-0031** |
| **2** | per-tenant / ephemeral containers appear (SaaS split, Plan 0037) | add **Traefik** behind Caddy on container hosts; Caddy routes `app.*`/tenant traffic to it | queued |
| **3** | a public, regulated, anonymous-traffic tier appears | add **nginx + WAF (Coraza/ModSecurity)** as the outermost moat in front of Caddy for *that tier only* | queued |

**Do not run all three from day one.** Today a stable cassette set needs only the
helm. nginx and Traefik are dormant capabilities, lit up precisely when their
strength becomes a need — never speculative complexity.

## Access model (from the WG + mTLS decision)

- **Mesh-only (WireGuard, no public DNS):** portainer, vault, admin, cockpit,
  beszel, uptime, workflow. Invisible to the internet.
- **Public + mTLS (Caddy refuses any device without a family client cert):**
  nephew, search, bank, clinic, hello, git, archive, historia. bank/vault also
  require the mesh. Family SSO layers inside for per-user identity.
- **Certs:** one `*.jailynmarvin.com` wildcard via DNS-01/acme-dns (covers public +
  mesh hosts; no per-host `_acme-challenge`).
