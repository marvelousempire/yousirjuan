---
ledgerId: LEDGER-0031
title: Cassette edge Phase 1 — Caddy at the helm (WG + mTLS, wildcard DNS-01, family CA)
status: in-progress
opened: 2026-06-02
closed: null
related-pains: []
related-tickets: [LEDGER-0028, LEDGER-0029]
triggers: [manual]
---

# LEDGER-0031 — Cassette edge Phase 1: Caddy at the helm

## Ask

Operator 2026-06-02:

> I want all cassettes hidden like Chase Bank … should not be exposed to public.
> … Hybrid of WireGuard + mTLS … Caddy [as helm] … Let's do that. Draw it up in
> yousirjuan and then make that plan a reality.

Phase 1 of the triple-threat edge ([`docs/edge-architecture-triple-threat.md`](../../docs/edge-architecture-triple-threat.md)):
**Caddy at the helm on both VPS + DGX**, enforcing the WG + mTLS access model.
Ops/secrets cassettes go WireGuard-only (no public DNS). Family apps stay public
but Caddy refuses any device without a **family client cert** (mTLS) — outsiders
get a dead connection, not a login page. One `*.jailynmarvin.com` wildcard via
DNS-01/acme-dns covers everything. Family SSO layers inside for per-user identity.

## Design

| Tier | Cassettes | Exposure |
|---|---|---|
| Mesh-only (WireGuard) | portainer, vault, admin, cockpit, beszel, uptime, workflow | no public DNS; mesh-only |
| Public + mTLS (Caddy) | nephew, search, bank, clinic, hello, git, archive, historia | public DNS; Caddy `client_auth require_and_verify` — no family cert → TLS refused. bank/vault also require the mesh |

- **Edge:** Caddy on VPS (migrated from nginx via reversible parallel-port cutover) **and** DGX (already Caddy). One config dialect both sides.
- **Certs:** `*.jailynmarvin.com` wildcard, Caddy-native DNS-01 via the `acmedns` module against `acme.jailynmarvin.com`.
- **Family CA:** EC P-256 private CA issues one client cert per device; per-device revoke + CRL.
- **Default-deny:** unknown Host → 404/abort; no-cert → handshake refused.

## Outcome

<fill on ship>

## Runbooks

- [01-bootstrap-family-ca.md](runbooks/01-bootstrap-family-ca.md) — stand up the EC private CA
- [02-issue-install-device-cert.md](runbooks/02-issue-install-device-cert.md) — issue + install a device cert (Mac/iOS)
- [03-caddy-edge-cutover.md](runbooks/03-caddy-edge-cutover.md) — deploy Caddy on the VPS via reversible parallel-port cutover (nginx kept as rollback)
- [04-dns-changes.md](runbooks/04-dns-changes.md) — WG-only deletes + SPF/api/sync fixes

## Playbooks

- [family-ca.sh](playbooks/family-ca.sh) — `init | issue-device <name> | revoke <name> | crl | issue-server <fqdn>`
- [Caddyfile](playbooks/Caddyfile) — cassette edge: wildcard DNS-01 + mTLS + Host-routing + default-deny (VPS & DGX)
- [acmedns.json.example](playbooks/acmedns.json.example) — acme-dns credential shape for the wildcard

## Replay (zero-AI)

```
# on each edge host (VPS + DGX), as root:
bash playbooks/family-ca.sh init                          # once, on the CA host; copy ca.crt to edges
cp playbooks/Caddyfile /etc/caddy/Caddyfile               # fill in acmedns + backend ports
caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
bash playbooks/family-ca.sh issue-device <device-name>    # per family device → .p12
```

## Verification

1. `curl https://nephew.jailynmarvin.com/` **no cert** → TLS handshake refused.
2. `curl --cert dev.crt --key dev.key https://nephew.jailynmarvin.com/` → 200 / SSO login.
3. `portainer.jailynmarvin.com` off-mesh → NXDOMAIN; on-mesh → reachable.
4. `curl -k -H 'Host: bogus.jailynmarvin.com' https://<edge>/` → default-deny.
5. `caddy validate` clean; wildcard cert auto-renews (Caddy logs show renewal).

## Undo

- `systemctl stop caddy && systemctl start nginx` (parallel-port cutover keeps nginx intact as instant rollback).
- DNS: re-add deleted CNAMEs.
- CA: `family-ca.sh revoke <name>` per device.
