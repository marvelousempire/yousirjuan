# LEDGER-0033 — jailynmarvin.com mail on clinic-vps

Self-hosted **docker-mailserver** at `/opt/mail-jailynmarvin` on `72.167.151.251`.

## Install (on VPS)

```bash
sudo bash /opt/mail-jailynmarvin/ledger-install.sh
```

Or from Mac after copying playbooks:

```bash
scp -r ledger/LEDGER-0033-mail-jailynmarvin/playbooks clinic-vps:/tmp/ledger-0033-mail/
ssh clinic-vps 'sudo bash /tmp/ledger-0033-mail/install.sh'
```

## Operator checklist

1. Read `DNS-CUTOVER-GODADDY.txt` on the VPS and apply records in GoDaddy.
2. If outbound mail fails: GoDaddy blocks port 25 — set `DEFAULT_RELAY_HOST` in `mailserver.env` (Brevo/Mailgun/SES) and recreate container.
3. Remove iCloud Custom Email Domain after MX propagates.
4. Upgrade TLS: `SSL_TYPE=letsencrypt` once `mail.jailynmarvin.com` resolves.

## Credentials

` /opt/mail-jailynmarvin/.primary-mail-password` — primary mailbox password (not in git).
