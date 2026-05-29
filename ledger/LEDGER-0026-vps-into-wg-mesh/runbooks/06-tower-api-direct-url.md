# 06 — Wire `NEPHEW_HERMES_DIRECT_URL` on the VPS tower-api

## Why

The Nephew tower-api uses `src/hermes-bridge.js` (in `marvelousempire/nephew`) to talk to the DGX's Hermes API. By default it tries an SSH tunnel via the alias `nephew-nivram` — that alias only exists in the Mac's `~/.ssh/config`, so it fails on the VPS. The bridge's v0.68.0 short-circuit (`NEPHEW_HERMES_DIRECT_URL`) lets the VPS dial the DGX directly over the WG mesh instead.

Mac runtime is unaffected — when the env var is absent, the existing SSH-tunnel path runs unchanged.

## Steps

```bash
ssh clinic-vps '
  grep -q NEPHEW_HERMES_DIRECT_URL ~/.nephew/tower.env || \
    echo "NEPHEW_HERMES_DIRECT_URL=http://192.168.8.249:8642/v1/chat/completions" >> ~/.nephew/tower.env
  systemctl --user restart nephew-tower-api
  sleep 2
  curl -s http://127.0.0.1:8088/api/agents/nephew-chat/status
'
```

The first `grep -q` makes the append idempotent — running this twice doesn't duplicate the line.

## Success criteria

```json
{
  "ok": true,
  "container": "up",
  "api": "connected",
  "models": ["qwen2.5:32b", ...],
  "tunnel": "direct-url",
  "dgx": "192.168.8.249:8642"
}
```

Then in a browser at `https://nephew.yousirjuan.ai/chat`:

- The HealthPill at the top-right shows green
- Sending a test message streams tokens

## Undo

```bash
ssh clinic-vps '
  sed -i "/^NEPHEW_HERMES_DIRECT_URL=/d" ~/.nephew/tower.env
  systemctl --user restart nephew-tower-api
'
```

The tower-api falls back to the legacy SSH-tunnel path (which won't work from the VPS, but the bridge will return a clean error instead of attempting an impossible config).
