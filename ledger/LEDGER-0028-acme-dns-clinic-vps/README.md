---
ledgerId: LEDGER-0028
title: Self-host acme-dns on clinic-vps so private wg-only hosts can get real LE certs without GoDaddy API access
status: proposed
opened: 2026-05-31
closed: null
related-pains: []
related-tickets: [LEDGER-0026]
triggers: [manual]
---

# LEDGER-0028 — acme-dns on clinic-vps

## Ask

The Claude Archive lives on the DGX Spark (`192.168.8.249`, on the family LAN). [Plan 0032 Phase A](https://github.com/marvelousempire/json-archive-chat-reader/blob/main/plans/0032-internal-auth-and-agent-sidecar.md) added internal session auth. The operator now wants to **upload from any device (Mac/iPad/iPhone) and view the same data**, reaching the DGX from outside the LAN.

Operator's verbatim 2026-05-30 picks (4-way AskUserQuestion):

> **Public exposure of the DGX:** Hold off — local network only for now.
> **Authentication:** Build proper in-app sessions (NextAuth / Lucia).
> **Domain:** Subdomain of yousirjuan.ai (Recommended).
> **LangGraph + Pydantic:** Python sidecar service.

And in follow-up 2026-05-31:

> Why do you keep offering Tailscale when we have WireGuard? We prefer privacy and to keep our info safe here rather than outside sources handling.

So: the dashboard wants a real LE cert (browser-trusted, no "ignore warning" hoops on iOS Safari), the URL is `https://archive.yousirjuan.ai`, and `yousirjuan.ai`'s DNS is at GoDaddy — which **locked down its DNS API in 2024** to $100M+ retail-spend accounts and Discount Domain Club members only. New general-purpose API keys are blocked, so Caddy can't do DNS-01 ACME against GoDaddy directly.

Tailscale and Cloudflare are off the table per the operator's privacy preference. `acme-dns` is the canonical workaround for exactly this: a tiny DNS server you self-host, GoDaddy gets ONE CNAME pointing at it for `_acme-challenge.archive.yousirjuan.ai`, and Caddy never touches GoDaddy's API.

`clinic-vps` is the natural home — it's already public (per [LEDGER-0026](../LEDGER-0026-vps-into-wg-mesh/)), the operator controls it, and adding one more container is cheap.

## Proposed outcome

`acme-dns` running on `clinic-vps`, listening on UDP/TCP 53 for delegated `_acme-challenge.*.yousirjuan.ai` records and TCP 8443 for registration/update API. GoDaddy gets two new records: `acme-dns.yousirjuan.ai → A → <clinic-vps IP>` and `acme-dns.yousirjuan.ai → NS → acme-dns.yousirjuan.ai.` (self-delegation). Each consumer (the DGX Caddy first; future private hosts later) calls the acme-dns registration endpoint once, gets a UUID, and adds ONE CNAME at GoDaddy: `_acme-challenge.<host>.yousirjuan.ai → <uuid>.acme-dns.yousirjuan.ai`. Caddy uses [`caddy-dns/acme-dns`](https://github.com/caddy-dns/acme-dns) to answer the challenge via the acme-dns API.

Nothing in the data path leaves family-owned infrastructure. acme-dns sees only ephemeral DNS-01 challenge strings (random base64) — not the certs themselves, not any traffic, not the resolved IPs. Let's Encrypt sees the domain name in public CT logs (unavoidable for any LE cert) and nothing else.

## Runbooks (to write before shipping)

- `01-vps-firewall.md` — open UDP/53, TCP/53, TCP/8443 on `clinic-vps` ufw; verify no conflict with the host's systemd-resolved
- `02-acme-dns-docker.md` — `docker run` config for `joohoi/acme-dns:latest`; persistent volume for the SQLite DB it uses; restart=unless-stopped
- `03-godaddy-delegation.md` — exact records to add at GoDaddy UI (A + NS for acme-dns.yousirjuan.ai, plus the per-consumer CNAME pattern)
- `04-register-and-use.md` — `curl POST /register` to acme-dns API, store the JSON credentials file, mount into Caddy on the consumer host

## Playbooks

- `register-acme-dns-account.sh` — one-liner that hits the acme-dns `/register` endpoint, prints the credentials JSON (operator pastes into the consumer's Caddy config). Idempotent in the sense that re-running just makes a new account; the old one keeps working.

## Replay (zero-AI)

To get an LE cert for a NEW private host:

```bash
# 1. From any machine that can hit the acme-dns API:
bash ledger/LEDGER-0028-acme-dns-clinic-vps/playbooks/register-acme-dns-account.sh > /tmp/acme-dns.json

# 2. Note the .subdomain UUID from /tmp/acme-dns.json. At GoDaddy, add:
#    _acme-challenge.<new-host>.yousirjuan.ai → CNAME → <uuid>.acme-dns.yousirjuan.ai

# 3. On the new host, drop /tmp/acme-dns.json into Caddy's config dir and
#    add the site block:
#      <new-host>.yousirjuan.ai {
#          tls {
#              dns acme-dns /etc/caddy/acme-dns.json
#          }
#          reverse_proxy <upstream>
#      }
#
# 4. Restart Caddy. LE cert issues within ~30s.
```

## Verification

```bash
# On clinic-vps:
sudo ss -lnup | grep ':53 '          # acme-dns is bound to UDP 53
docker logs acme-dns --tail 20       # registrations + challenge updates

# From anywhere:
dig +short NS acme-dns.yousirjuan.ai            # → acme-dns.yousirjuan.ai. (self-delegation)
dig +short @acme-dns.yousirjuan.ai TXT _acme-challenge.test.yousirjuan.ai  # → empty (or actual challenge if test cert in flight)

# On the consumer (DGX, Caddy):
docker compose logs caddy | grep -i "obtained certificate"   # success log
curl -sI https://<new-host>.yousirjuan.ai | head -1          # HTTP/2 200
```

## Out of scope

- ACME challenges for **public** hosts via acme-dns — those still work fine through HTTP-01 / TLS-ALPN-01 (the existing path for `nephew.yousirjuan.ai`, `clinic.yousirjuan.ai`, etc.). acme-dns is specifically the **private-host** answer.
- Replacing GoDaddy as the registrar. Keep registration there; this only adds DNS records.
- Moving DNS hosting off GoDaddy entirely. Possible follow-up; not this plan.

## Related

- `marvelousempire/json-archive-chat-reader/plans/0033-wg-acme-dns-archive-yousirjuan-ai.md` — the consumer plan; first archive of acme-dns. Uses this ledger's output to provision `https://archive.yousirjuan.ai`.
- [LEDGER-0026](../LEDGER-0026-vps-into-wg-mesh/) — the wg mesh this depends on (clinic-vps is already a peer).
