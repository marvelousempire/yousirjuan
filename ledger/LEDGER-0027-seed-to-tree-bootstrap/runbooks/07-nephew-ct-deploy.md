# 07 — Nephew Control Tower Deploy (VPS-side)

## Why

`nephew.yousirjuan.ai` serves a Vite/React static build (the Nephew Control Tower) plus an nginx layer that proxies `/api/*` to either Bishop (auth) or tower-api (chat + control tower). This runbook describes the deploy chain.

## Steps

### 1. From the operator's Mac — push code to origin

```bash
cd ~/Developer/nephew
git push origin main
```

### 2. Run `make deploy`

```bash
cd ~/Developer/nephew
make deploy
```

That runs `scripts/deploy-control-tower-vps.sh` which:

- SSH's to `clinic-vps`
- `cd /opt/nephew && git fetch origin && git checkout main && git merge --ff-only origin/main`
- `pnpm install` + `pnpm build` (in `apps/control-tower`)
- `sudo cp` the new nginx site config + `sudo systemctl reload nginx`
- Runs the smoke test loop against every public CT route

### 3. Critical nginx routes

The nginx config at `/etc/nginx/sites-enabled/nephew.yousirjuan.ai` MUST contain these location blocks in order:

```
location ~ ^/api/v1/auth/(sso|exchange|\.well-known) { proxy_pass http://127.0.0.1:8000; }   # Bishop
location ~ ^/api/v1/nephew/(.*)$ { proxy_pass http://127.0.0.1:8088/api/v1/$1; }              # tower-api with prefix strip
location ~ ^/api/v1/(auth|control-tower-apps|admin|healthz|operator|tower-status|brains|marketplace|rules|telemetry|handbook|preflight|route|loop) { proxy_pass http://127.0.0.1:8088; }  # tower-api specific routes
location ~ ^/api/agents/ { proxy_pass http://127.0.0.1:8088; ... }                             # NEW — chat surface routes
location /api/ { proxy_pass http://127.0.0.1:8000; }                                          # Bishop catch-all
location /oauth/ { proxy_pass http://127.0.0.1:8000/api/v1/auth/oauth/; }
location / { root /opt/nephew/apps/control-tower/dist; try_files $uri /index.html; }
```

The `/api/agents/` block MUST come BEFORE the `/api/` catch-all. Order is significant.

### 4. SSE-friendly settings on /api/agents/

The chat streams Server-Sent Events. The `/api/agents/` location block needs:

```
proxy_buffering off;
proxy_cache off;
proxy_read_timeout 300s;
proxy_send_timeout 300s;
```

Without these, nginx buffers the SSE stream and tokens arrive only at the end.

The full template is at `artifacts/vps-nginx-agents.conf` in this ledger.

## Success criteria

```bash
curl -fI https://nephew.yousirjuan.ai/                              # 200 + valid TLS
curl -fI https://nephew.yousirjuan.ai/chat                          # 200
curl -s https://nephew.yousirjuan.ai/api/agents/nephew-chat/status  # {"ok":true,...}
```

Browser at `https://nephew.yousirjuan.ai/chat` — HealthPill shows green; sending a message streams tokens.

## Undo

```bash
ssh clinic-vps '
sudo cp /etc/nginx/sites-enabled/nephew.yousirjuan.ai.bak-<timestamp> /etc/nginx/sites-enabled/nephew.yousirjuan.ai
sudo nginx -t && sudo systemctl reload nginx
'
```

Or roll back code to a prior commit:

```bash
cd ~/Developer/nephew
git revert <bad-commit>
make deploy
```
