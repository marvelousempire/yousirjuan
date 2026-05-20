# Runbook 01 — Obtain GoDaddy API credentials (operator-only)

**Time:** ~3 minutes
**Reversible:** yes (revoke at the same portal)
**Prereqs:** operator's GoDaddy account login

## Why this can't be automated

GoDaddy doesn't expose API-key creation via API (chicken-and-egg). The operator has to log into the GoDaddy account portal once, generate a Production API key + secret, and stash them on the iMac.

## Steps

1. Sign in: https://developer.godaddy.com/
2. Click **API Keys** in the top-right menu.
3. Click **Create New API Key**.
4. **Name:** `yousirjuan-failover-watchdog` (or anything descriptive).
5. **Environment:** **Production**. (Not OTE — that's the test API.)
6. Click **Next**. GoDaddy displays the key + secret **ONCE**. Copy both immediately to a password manager.
7. On the iMac, save them as a chmod 600 env file:

```bash
mkdir -p ~/.config/yousirjuan && \
chmod 700 ~/.config/yousirjuan && \
cat > ~/.config/yousirjuan/godaddy.env <<'EOF'
GODADDY_API_KEY=paste-key-here
GODADDY_API_SECRET=paste-secret-here
EOF
chmod 600 ~/.config/yousirjuan/godaddy.env
```

The file is NEVER committed (path is outside repo and gitignored as a defensive measure).

## Pre-flight test

```bash
bash ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/godaddy-dns.sh \
  get yousirjuan.ai hello
```

Should print the current A-record IP for `hello.yousirjuan.ai` (one line, one value). If it errors with `404` or `403`, double-check that the key is Production (not OTE) and that `yousirjuan.ai` lives in this account.

## TTL pre-lowering (do this once before going live)

GoDaddy's default A-record TTL is **3600 seconds (1 hour)**. That's the upper bound on failover propagation time. **Lower it to 60s on each failover-eligible subdomain BEFORE the watchdog goes live**, so the swap takes effect in ~1 min instead of ~1 hour.

For each subdomain in your `TARGETS` list:

```bash
bash ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/godaddy-dns.sh \
  get yousirjuan.ai hello
# Note the current IP (e.g., 72.167.151.251) — you'll re-set the same IP with TTL 60:
bash ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/godaddy-dns.sh \
  set yousirjuan.ai hello 72.167.151.251 60
```

OR via the GoDaddy DNS Manager web UI: yousirjuan.ai → DNS → each A record → edit → TTL = "1/2 hour" or "custom: 60 seconds." Save.

**Caveat:** Lower TTL means slightly more DNS queries from resolvers globally. For our traffic level this is negligible.

## Security notes

- The API key + secret give FULL control of all DNS records on every domain in the GoDaddy account. **Treat them like root credentials.**
- If the iMac is ever compromised, **revoke and rotate** at the GoDaddy Developer portal. Same UI as creation.
- The watchdog never sends the key/secret over the network except to GoDaddy's API over HTTPS.

## Undo

Revoke the API key at https://developer.godaddy.com/keys → click the key → **Delete**. Watchdog goes back to DRY_RUN-effective (calls will fail with 401).

## Related

- [02-watchdog-design.md](02-watchdog-design.md) — what the watchdog uses the credentials for.
- [03-enabling-real-swap.md](03-enabling-real-swap.md) — the go-live checklist that depends on this runbook.
