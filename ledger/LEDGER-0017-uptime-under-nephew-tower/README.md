---
ledgerId: LEDGER-0017
title: Move Uptime Kuma under Nephew Tower — `nephew.yousirjuan.ai/uptime/` (one Tower, one URL)
status: in-progress
opened: 2026-05-21
closed: null
related-tickets: [LEDGER-0016]
triggers:
  - manual-cli: `sudo bash ledger/LEDGER-0017-uptime-under-nephew-tower/playbooks/move-uptime-under-nephew.sh`
---

# LEDGER-0017 — Uptime Kuma under Nephew Tower

## Ask

Operator 2026-05-21: *"can we just add that to the Control Tower which is the Nephew UI instead of 'uptime.yousirjuan.ai'?"*

LEDGER-0016 shipped Uptime Kuma as a standalone subdomain. Operator's preference: keep everything under the one Nephew Tower URL so there's a single control surface, not a sprawl of subdomains.

## Outcome

Uptime Kuma now serves at **`https://nephew.yousirjuan.ai/uptime/`** via path-based nginx routing.

Changes:
1. **`URL_BASE_PATH=/uptime`** added to the Uptime Kuma container env so all asset URLs are prefixed correctly
2. **`location /uptime/`** block inserted into `/etc/nginx/sites-enabled/nephew.yousirjuan.ai` BEFORE the `location /` catchall (with WebSocket upgrade headers)
3. **Standalone `uptime.yousirjuan.ai` vhost removed** — moved to `/etc/nginx/sites-backups/`
4. GoDaddy A record for `uptime.yousirjuan.ai` can be deleted (no longer needed)

## Playbook

- [move-uptime-under-nephew.sh](playbooks/move-uptime-under-nephew.sh) — idempotent. Patches Kuma compose, backs up + inserts nginx vhost block, removes standalone vhost, reloads nginx, verifies HTTP response.

## Replay

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0017-uptime-under-nephew-tower/playbooks/move-uptime-under-nephew.sh'
```

## Verification

```bash
curl -sI https://nephew.yousirjuan.ai/uptime/
# HTTP/2 302 (Kuma's first-time-setup redirect — correct response)
```

Then visit `https://nephew.yousirjuan.ai/uptime/` in browser, complete admin setup.

## Phase 2 (nephew repo PR)

Add an "Uptime" nav entry in Nephew Control Tower's `tower-nav.ts` under the Infrastructure group:

```ts
{ href: "/uptime/", label: "Uptime", subtitle: "Kuma external monitor (LEDGER-0016)", keywords: ["uptime", "kuma", "monitor"] }
```

That gives operator a one-click jump from any Tower page directly to the Kuma UI (which now lives under the same domain, so no CORS, no auth re-prompt if shared session).

## Undo

```bash
# Restore the standalone subdomain:
ssh vps-godaddy '
  sudo cp /etc/nginx/sites-backups/uptime.yousirjuan.ai.bak-*-pre-LEDGER-0017 \
       /etc/nginx/sites-enabled/uptime.yousirjuan.ai
  sudo cp /etc/nginx/sites-backups/nephew.yousirjuan.ai.bak-<timestamp> \
       /etc/nginx/sites-enabled/nephew.yousirjuan.ai
  sudo nginx -t && sudo nginx -s reload
  # Remove URL_BASE_PATH from /opt/uptime-kuma/docker-compose.yml then:
  cd /opt/uptime-kuma && sudo docker compose down && sudo docker compose up -d
'
```

## Why path-based vs subdomain

| Path-based (this) | Subdomain (LEDGER-0016 original) |
|---|---|
| One DNS record for everything | Separate A record per surface |
| One TLS cert | One cert per subdomain |
| Cookie / auth context unified | Each subdomain isolated |
| Operator mental model: "Tower has X" | Operator mental model: "X is its own thing" |
| Future surfaces add as more `/path/` | Future surfaces add as more subdomains |

Operator preference + scaling argument both favor path-based for this control-tower architecture.

## Cross-references

- LEDGER-0016 — original standalone Kuma setup (this supersedes its nginx vhost decision)
- LEDGER-0013 — wire-marvelous-app.sh + nginx vhost pattern (different — that's for separate apps with their own subdomains; this is for sub-paths under the Tower)
- LEDGER-0005 — GitLab as sovereign source-of-truth (also has its own subdomain; that's intentional because it serves git over SSH on port 2424 which requires a dedicated TLS cert)
