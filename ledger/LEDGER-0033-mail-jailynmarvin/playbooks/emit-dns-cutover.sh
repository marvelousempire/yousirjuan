#!/usr/bin/env bash
set -euo pipefail
MAIL_ROOT="${1:-/opt/mail-jailynmarvin}"
OUT="$MAIL_ROOT/DNS-CUTOVER-GODADDY.txt"
DKIM_DIR="$MAIL_ROOT/docker-data/dms/config/opendkim/keys/jailynmarvin.com"
VPS_IP="${VPS_IP:-72.167.151.251}"

DKIM_TXT=""
if [[ -f "$DKIM_DIR/mail.txt" ]]; then
  _p="$(grep -oE '"[^"]+"' "$DKIM_DIR/mail.txt" | tr -d '"' | tr -d ' \t\n' | sed 's/v=DKIM1;h=sha256;k=rsa;//g' | sed 's/p=//g')"
  if [[ -n "$_p" ]]; then
    DKIM_TXT="v=DKIM1; h=sha256; k=rsa; p=${_p}"
  fi
fi

cat >"$OUT" <<EOF
# GoDaddy DNS — jailynmarvin.com mail cutover (LEDGER-0033)
# Apply at https://dcc.godaddy.com/manage/jailynmarvin.com/dns

## Add / update
A     mail     $VPS_IP
MX    @        10 mail.jailynmarvin.com.
TXT   @        v=spf1 mx a:mail.jailynmarvin.com -all
TXT   _dmarc   v=DMARC1; p=quarantine; rua=mailto:postmaster@jailynmarvin.com
$(if [[ -n "$DKIM_TXT" ]]; then echo "TXT   mail._domainkey"; echo "      (paste as one line in GoDaddy TXT value field)"; echo "      $DKIM_TXT"; else echo "# TXT mail._domainkey — run emit-dns-cutover.sh after DKIM exists"; fi)

## Remove (after 48h successful mail)
MX    @        mx01.mail.icloud.com / mx02.mail.icloud.com
CNAME sig1._domainkey   icloud DKIM
TXT   @        apple-domain=...
TXT   @        v=spf1 include:icloud.com (fix doubled-quote bug if keeping iCloud temporarily)

## Apple
Remove jailynmarvin.com from iCloud Custom Email Domain after MX cutover.

## TLS upgrade (after mail A record propagates)
On VPS: edit $MAIL_ROOT/mailserver.env → SSL_TYPE=letsencrypt SSL_DOMAIN=mail.jailynmarvin.com
Then: cd $MAIL_ROOT && docker compose up -d --force-recreate
EOF

chmod 644 "$OUT"
echo "Wrote $OUT"
