# DNS zone — jailynmarvin.com (captured 2026-06-02 06:51 UTC)

> Provider: **GoDaddy** (`ns47/ns48.domaincontrol.com`) — DNS-only, no proxy layer.
> Archival snapshot + findings. Companion to
> [`cassette-subdomain-edge-architecture.md`](cassette-subdomain-edge-architecture.md).

## Captured zone

```dns
$ORIGIN jailynmarvin.com.

; SOA
@   3600 IN SOA ns47.domaincontrol.com. dns.jomax.net. ( 2026060215 28800 7200 604800 3600 )

; A
@     600 IN A 72.167.151.251
acme  600 IN A 72.167.151.251
api   600 IN A 72.167.151.251
edge  600 IN A 72.167.151.251
sync  600 IN A 72.167.151.251

; TXT
@               3600 IN TXT ""v=spf1 include:icloud.com ~all""        ; <-- DOUBLED QUOTES (bug)
@               3600 IN TXT "apple-domain=KFdYIuQk4DNIzyKy"
_acme-challenge  600 IN TXT "0lb7wbdFKujWycIGO7Jd6ptU2GqquYD3KnYxgCyvjb0"
_acme-challenge  600 IN TXT "7WhrYXvntN677E78pDQ6Z_7uSOC_RJSP4c98QT26VNM"

; CNAME  (→ edge anchor = Option A)
admin     600 IN CNAME edge.jailynmarvin.com.
archive   600 IN CNAME edge.jailynmarvin.com.
bank      600 IN CNAME edge.jailynmarvin.com.
beszel    600 IN CNAME edge.jailynmarvin.com.
clinic    600 IN CNAME edge.jailynmarvin.com.
cockpit   600 IN CNAME edge.jailynmarvin.com.
git       600 IN CNAME edge.jailynmarvin.com.
hello     600 IN CNAME edge.jailynmarvin.com.
historia  600 IN CNAME edge.jailynmarvin.com.
nephew    600 IN CNAME edge.jailynmarvin.com.
portainer 600 IN CNAME edge.jailynmarvin.com.
search    600 IN CNAME edge.jailynmarvin.com.
uptime    600 IN CNAME edge.jailynmarvin.com.
vault     600 IN CNAME edge.jailynmarvin.com.
workflow  600 IN CNAME edge.jailynmarvin.com.
www       3600 IN CNAME @
sig1._domainkey 3600 IN CNAME sig1.dkim.jailynmarvin.com.at.icloudmailadmin.com.
_acme-challenge.search 600 IN CNAME a05f4b61-…-09fd881c059f.acme.jailynmarvin.com.
_domainconnect  3600 IN CNAME _domainconnect.gd.domaincontrol.com.

; CAA
@ 600 IN CAA 0 issue     "letsencrypt.org"
@ 600 IN CAA 0 issuewild  "letsencrypt.org"
@ 600 IN CAA 0 iodef      "mailto:abrownsanta@jailynmarvin.com"

; NS (acme = acme-dns DNS-01 delegation)
@    3600 IN NS ns47.domaincontrol.com.
@    3600 IN NS ns48.domaincontrol.com.
acme  600 IN NS acme.jailynmarvin.com.

; MX (iCloud mail)
@ 3600 IN MX 10 mx01.mail.icloud.com.
@ 3600 IN MX 10 mx02.mail.icloud.com.
```

## Findings

**✅ Option A already in place.** One `edge` A anchor; 15 cassettes are `CNAME → edge`
(admin, archive, bank, beszel, clinic, cockpit, git, hello, historia, nephew,
portainer, search, uptime, vault, workflow). No wildcard. CAA pins Let's Encrypt.
acme-dns DNS-01 delegation (`acme` A+NS, `_acme-challenge.*`) is intentional — leave it.

**🔴 Bug — SPF record has doubled quotes.** `""v=spf1 include:icloud.com ~all""`
embeds literal `"` characters, so the SPF string is malformed → iCloud SPF can fail.
Fix to a single pair: `"v=spf1 include:icloud.com ~all"`.

**🟠 Consistency — `api` and `sync` are A records, not CNAMEs.** Convert both to
`CNAME → edge.jailynmarvin.com.` so the IP lives only in `edge` and DGX failover stays
a one-record edit.

**🟠 Security — sensitive ops UIs are publicly resolvable.** `portainer`, `vault`,
`admin`, `cockpit`, `beszel`, `uptime`, `workflow` all resolve to the public edge.
Per "only Private," these should be **WireGuard-only** (no public CNAME) OR sit behind
the **edge default-deny vhost + strong per-app auth**. Public DNS for an admin/secrets
UI is exposure even if the app has a login. Decide per cassette: public product
(nephew/search/bank/hello) vs. private ops (the rest → WG).

**ℹ️ Apex failover.** `@` must stay an A record (DNS forbids CNAME at apex); `www → @`
follows it. On DGX failover, update **both** `@` and `edge` A records.
