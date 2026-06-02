# 04 — DNS changes (GoDaddy)

Apply alongside the Caddy cutover. Provider: GoDaddy (`domaincontrol.com`).
Source zone: [`docs/dns-jailynmarvin-zone-2026-06-02.md`](../../../docs/dns-jailynmarvin-zone-2026-06-02.md).

## A. Make ops cassettes mesh-only (delete their public CNAMEs)
Remove these CNAMEs so they no longer resolve publicly (reach them over WireGuard):
```
admin      (delete)
cockpit    (delete)
portainer  (delete)
vault      (delete)
beszel     (delete)      # your call — monitoring
uptime     (delete)      # your call
workflow   (delete)      # your call
```
Keep (public + mTLS): `nephew, search, bank, clinic, hello, git, archive, historia`.

## B. Fix the SPF bug (email)
Change the apex TXT from the doubled-quote form to a single value:
```
v=spf1 include:icloud.com ~all
```
(In GoDaddy's TXT field, enter it WITHOUT surrounding quotes — GoDaddy adds them.)

## C. Consistency — api/sync → CNAME edge
Convert `api` and `sync` from A records to:
```
api   CNAME  edge.jailynmarvin.com.
sync  CNAME  edge.jailynmarvin.com.
```

## Leave alone
`edge` A, the kept cassette CNAMEs, CAA (Let's Encrypt), the `acme` A+NS + `_acme-challenge.*`
delegation (acme-dns DNS-01), MX/DKIM (iCloud), apex `@` A (DNS forbids CNAME at apex).

## Success criteria
- `dig +short portainer.jailynmarvin.com` → NXDOMAIN (off-mesh).
- `dig +short api.jailynmarvin.com` → resolves via `edge` (CNAME).
- SPF validates: `dig +short TXT jailynmarvin.com` shows one clean `v=spf1 …` string.

## Undo
Re-add the deleted CNAMEs (value `edge.jailynmarvin.com.`); revert api/sync to A `72.167.151.251` if needed.
