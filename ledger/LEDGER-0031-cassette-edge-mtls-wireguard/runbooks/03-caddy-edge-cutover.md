# 03 — Deploy Caddy on the VPS via reversible parallel-port cutover

Migrate the VPS public edge from nginx to Caddy **without a blind switch** — nginx
stays running as instant rollback until Caddy is proven.

## Prereqs
- Caddy built with the acme-dns module: `xcaddy build --with github.com/caddy-dns/acmedns`.
- `/etc/caddy/acmedns.json` filled from `acmedns.json.example` (0600 root:root); export `ACMEDNS_USER/PASS/SUBDOMAIN`.
- Family CA `ca.crt` at `/etc/caddy/jailynmarvin-ca.crt` (runbook 01).

## Steps
1. **Stage Caddy on alternate ports** (e.g. `:8443`/`:8081`) — copy `playbooks/Caddyfile`, set backend ports, then:
   ```bash
   caddy validate --config /etc/caddy/Caddyfile
   ```
2. **Prove it on the alt port** (nginx still owns :443):
   ```bash
   curl --cert dev.crt --key dev.key --resolve nephew.jailynmarvin.com:8443:127.0.0.1 https://nephew.jailynmarvin.com:8443/   # 200
   curl --resolve nephew.jailynmarvin.com:8443:127.0.0.1 https://nephew.jailynmarvin.com:8443/                                # TLS refused (no cert)
   ```
   Verify the wildcard cert issued (Caddy logs) and every cassette routes.
3. **Cut over** — stop nginx, move Caddy to `:443/:80`, reload:
   ```bash
   systemctl stop nginx
   # set Caddy to :443/:80 in the Caddyfile, then:
   systemctl reload caddy
   ```
4. **Smoke** every public cassette with + without a cert (success criteria below).

## Success criteria
- All public cassettes 200 **with** a family cert, **TLS-refused without**.
- `bogus.jailynmarvin.com` Host → `abort`/default-deny.
- Wildcard `*.jailynmarvin.com` cert present and auto-renewing.

## Undo (instant rollback)
```bash
systemctl stop caddy && systemctl start nginx   # nginx config was never removed
```
Keep nginx installed until Caddy has run clean through at least one cert renewal.

## DGX failover
The DGX already runs Caddy — drop the same `Caddyfile` + `ca.crt` there so the
mTLS model survives failover. (Caddy does the DNS-01 wildcard natively on that side too.)
