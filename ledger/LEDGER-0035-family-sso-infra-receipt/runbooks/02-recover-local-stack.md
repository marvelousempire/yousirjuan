# Runbook 02 — Recover local family stack (operator Mac)

## Steps

From **nephew** checkout on operator Mac:

```bash
make down
POCKIT_LOCAL_ONLY=1 make pockit
make doors    # optional once — clean http://pockit.localhost/
```

`POCKIT_LOCAL_ONLY=1` skips apex deploy (nephew-ct SSH) — local SSO does not require VPS reachability.

## Browser

1. Clear all **`nephew_session`** cookies on `*.localhost`.
2. Open **`http://pockit.localhost/signin`**.
3. Sign in with credentials from **`~/.nephew/tower.env`** (family operator — not ReadyPlay Admin).

## Verify tower-api stayed up

```bash
lsof -nP -iTCP:8088 -sTCP:LISTEN
curl -sf 'http://127.0.0.1:8088/healthz'
```

If tower-api dies immediately after boot, see nephew `docs/Issue-Log.md` and `~/.nephew/run/tower-api.log`.
