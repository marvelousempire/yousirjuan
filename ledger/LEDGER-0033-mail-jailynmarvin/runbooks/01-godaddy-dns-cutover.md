# Runbook 01 — GoDaddy DNS cutover

Mail runs on **clinic-vps** (`72.167.151.251`). The server is installed; DNS must be applied manually.

## Records to add

| Type | Name | Value |
|------|------|--------|
| A | `mail` | `72.167.151.251` |
| MX | `@` | `10` → `mail.jailynmarvin.com` |
| TXT | `@` | `v=spf1 mx a:mail.jailynmarvin.com -all` |
| TXT | `_dmarc` | `v=DMARC1; p=quarantine; rua=mailto:postmaster@jailynmarvin.com` |
| TXT | `mail._domainkey` | Full DKIM line from VPS: `cat /opt/mail-jailynmarvin/DNS-CUTOVER-GODADDY.txt` |

## Remove after 48h of good mail

- MX → `mx01.mail.icloud.com` / `mx02.mail.icloud.com`
- CNAME `sig1._domainkey` → iCloud
- TXT `apple-domain=…`
- Broken iCloud SPF TXT

## Apple

Settings → Apple ID → iCloud → Custom Email Domain — remove `jailynmarvin.com` after MX propagates.

## Verify

```bash
dig +short mail.jailynmarvin.com A
dig +short jailynmarvin.com MX
nc -zv mail.jailynmarvin.com 25 587 143
```

Use **IMAP port 143 with STARTTLS** if port 993 is refused (GoDaddy may filter 993).
