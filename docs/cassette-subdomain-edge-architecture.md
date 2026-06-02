# Cassette Subdomain & Edge Architecture

> **Status:** adopted 2026-06-02 · **Family TLD:** `jailynmarvin.com`
> **Companion docs:** [`whitepaper-hardware-network.md`](whitepaper-hardware-network.md) ·
> [`private-ai-network-handoff.md`](private-ai-network-handoff.md) ·
> [`multi-tenant-architecture.md`](multi-tenant-architecture.md) ·
> rule [`one-tower-one-url`](../.claude/rules/one-tower-one-url.md)

## Relationship to One-Tower-One-URL

This doc is **not** a license to spray subdomains. Per the
[`one-tower-one-url`](../.claude/rules/one-tower-one-url.md) rule, a browser-facing
UI **defaults to embedding inside the Nephew Control Tower** at
`nephew.jailynmarvin.com/apps/<id>` — one nav, one auth, one cert, one bookmark. A
**dedicated subdomain is the exception**, justified only when:

- the cassette speaks a non-HTTP protocol on its own port (e.g. `git` → SSH :2424),
- it serves public/third-party traffic,
- it needs its own TLS-termination logic, or
- **the operator explicitly directs a per-cassette subdomain** — which is the case
  here (operator direction, 2026-06-02).

So: **Tower-embed is the default; this doc governs the cassettes that legitimately
get their own subdomain.** When a new cassette appears, first ask "embed in Tower?"
— and only if the answer is no does the new-cassette ritual below apply.

## Principle

Every cassette in the Framework gets **its own subdomain** of the family TLD —
`nephew.jailynmarvin.com`, `search.jailynmarvin.com`, `bank.jailynmarvin.com`,
and so on. Subdomains are the unit of addressing; the reverse-proxy edge is the
unit of routing and access control.

Two non-negotiables shape the design (Trust Protocol §3 — privacy/security
always):

1. **Least exposure.** Only names we explicitly create should resolve. The public
   DNS zone IS the public allowlist.
2. **Only Private by default.** A public subdomain exists only for cassettes that
   are *meant* to be public. Anything private is reached over the **WireGuard
   mesh** and gets **no public DNS record at all**.

## Decision: Option A — single `edge` anchor + CNAME per cassette

We use **explicit per-cassette records**, not a wildcard. To avoid per-cassette IP
toil, exactly one record holds the IP (`edge`), and every cassette is a **CNAME**
to it.

### DNS records (provider: **GoDaddy** `ns47/ns48.domaincontrol.com` — DNS-only, no proxy layer; see [`dns-jailynmarvin-zone-2026-06-02.md`](dns-jailynmarvin-zone-2026-06-02.md))

**Anchor (the only record that holds the IP):**

| Type | Name | Value | Proxy | TTL |
|------|------|-------|-------|-----|
| A | `edge` | `72.167.151.251` (VPS edge) | DNS only | Auto |

**Cassettes (CNAME → `edge`):**

| Type | Name | Value | Proxy | TTL |
|------|------|-------|-------|-----|
| CNAME | `nephew` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `search` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `bank` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `clinic` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `git` | `edge.jailynmarvin.com` | DNS only | Auto |

**Future cassettes — add one row when (and only when) each goes public:**

| Type | Name | Value | Proxy | TTL |
|------|------|-------|-------|-----|
| CNAME | `dockyard` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `dustpan` | `edge.jailynmarvin.com` | DNS only | Auto |
| CNAME | `<new-cassette>` | `edge.jailynmarvin.com` | DNS only | Auto |

## Why explicit records, not a wildcard

| | Explicit records (chosen) | Wildcard `*.jailynmarvin.com` |
|---|---|---|
| Exposure | Only listed names resolve; everything else → **NXDOMAIN** | **Every** name resolves to the edge → free recon, larger surface |
| Unknown hostnames | Never reach a backend (don't resolve + edge default-deny) | Hit the edge; rely entirely on a default-deny vhost |
| TLS blast radius | Per-host certs — one leaked key ≠ all subdomains | Usually one wildcard cert — leaked key impersonates **every** subdomain |
| Auditability | The zone IS the allowlist — exactly what's exposed | Implicit; can't tell what's live from DNS |
| Per-cassette DNS work | One CNAME line (mitigated by the `edge` anchor) | Zero |

A wildcard's only win is convenience; the `edge`-anchor pattern recovers almost
all of that convenience (the IP lives in one place) without the exposure and
key-blast-radius costs. **If a wildcard is ever used, it is valid only with a
strict edge default-deny vhost (below).**

## The layer that makes it airtight: edge default-deny

All cassettes share **one edge IP** (the VPS, `72.167.151.251`), so isolation is
enforced at the **reverse proxy**, not the network. The edge MUST:

- Route by `Host` header — each cassette vhost proxies **only** its own backend.
- **Default-deny unknown hosts** — any hostname without an explicit vhost
  (including `edge.jailynmarvin.com` itself) is refused (nginx `return 444` / a
  closed default `server` block; Caddy: no catch-all → connection refused / 403).

DNS is the first filter (unlisted names → NXDOMAIN); the default-deny vhost is the
second (listed-but-unconfigured names → refused). Belt and suspenders.

## TLS

Per-host certificates (Let's Encrypt), **not** a wildcard cert. A CNAME does not
change issuance — `nephew.jailynmarvin.com` gets its own cert whether it's an A or
a CNAME. Smaller key blast radius; each host independently revocable.

## DGX failover (bonus of the `edge` anchor)

Because every cassette is a CNAME to `edge`, failover is a **single edit**: point
`edge`'s A record at the DGX (over the WireGuard mesh) and **all** cassettes follow
instantly — no per-cassette changes. This implements the DGX-failover policy: when
the VPS is down, the family stack fails over to the DGX as primary.

## New-cassette ritual (3 explicit, auditable steps)

1. **DNS** — add one `CNAME <name> → edge.jailynmarvin.com` (grey-cloud).
2. **Edge** — add the reverse-proxy vhost for `<name>.jailynmarvin.com` → that
   cassette's backend (and nothing else).
3. **TLS** — add `<name>.jailynmarvin.com` to certificate issuance.

No wildcard means anything not run through these three steps simply does not exist
to the outside world.

## Current state (2026-06-02 — from the captured zone)

- **Option A is live.** `edge` A → `72.167.151.251`; **15 cassettes are already
  `CNAME → edge`**: admin, archive, bank, beszel, clinic, cockpit, git, hello,
  historia, nephew, portainer, search, uptime, vault, workflow. No wildcard.
- CAA pins Let's Encrypt (`issue` + `issuewild`); acme-dns DNS-01 delegation in place.
- **Open fixes** (see the zone doc's Findings): SPF TXT has doubled quotes (bug);
  `api` + `sync` are still A records (convert to CNAME→edge); sensitive ops UIs
  (portainer/vault/admin/cockpit/beszel/uptime/workflow) are publicly resolvable and
  should move behind WireGuard or sit strictly behind the edge default-deny + auth.
