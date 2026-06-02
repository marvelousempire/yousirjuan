# 01 — Bootstrap the family CA

Stand up the private EC P-256 CA that signs every family device's mTLS cert.
Run **once**, on a secure host (the VPS or DGX — keep `ca.key` off laptops).

```bash
sudo FAMILY_CA_DIR=/etc/jailynmarvin-ca bash playbooks/family-ca.sh init
sudo cp /etc/jailynmarvin-ca/ca.crt /etc/caddy/jailynmarvin-ca.crt   # the mTLS trust anchor
```

Then point the Caddyfile's `client_auth > trust_pool file` at `/etc/caddy/jailynmarvin-ca.crt`
and copy that same `ca.crt` to the DGX failover edge.

## Success criteria
- `/etc/jailynmarvin-ca/ca.crt` and `ca.key` exist; `ca.key` is `0600`.
- `openssl x509 -in /etc/jailynmarvin-ca/ca.crt -noout -subject` shows the family Root CA.

## Undo
- Archive + remove `/etc/jailynmarvin-ca`. (Only safe once no edge references the cert and no device certs are in use.)

## Security
- `ca.key` is the family's mTLS master — treat like the Ed25519 master key: never leaves this host, never committed, backed up encrypted.
