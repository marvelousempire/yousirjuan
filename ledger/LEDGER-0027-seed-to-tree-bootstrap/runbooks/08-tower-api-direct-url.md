# 08 — Tower-API `NEPHEW_HERMES_DIRECT_URL` (VPS-side)

## Why

The Nephew tower-api uses `src/hermes-bridge.js` (in `marvelousempire/nephew`) to talk to the DGX hermes API. By default it tries an SSH tunnel via the alias `nephew-nivram` — that alias only exists in the Mac's `~/.ssh/config`, so it fails on the VPS. The bridge's v0.68.0 short-circuit (`NEPHEW_HERMES_DIRECT_URL`) lets the VPS dial the DGX directly over the WG mesh instead.

Mac runtime is unaffected — when the env var is absent, the existing SSH-tunnel path runs unchanged.

## Steps

The tower-api systemd unit has hardcoded `Environment=` lines but no `EnvironmentFile`. To inject the env var without modifying the unit, use a drop-in override.

```bash
ssh clinic-vps '
mkdir -p ~/.config/systemd/user/nephew-tower-api.service.d
cat > ~/.config/systemd/user/nephew-tower-api.service.d/direct-url.conf <<EOF
[Service]
Environment=NEPHEW_HERMES_DIRECT_URL=http://192.168.8.249:8642/v1/chat/completions
EOF
systemctl --user daemon-reload
systemctl --user restart nephew-tower-api
'
```

The drop-in file persists across reboots. Tower-api picks up the env var on every restart.

## Success criteria

```bash
ssh clinic-vps '
PID=$(systemctl --user show -p MainPID --value nephew-tower-api)
sudo cat /proc/$PID/environ | tr "\0" "\n" | grep NEPHEW_HERMES_DIRECT_URL
'
# NEPHEW_HERMES_DIRECT_URL=http://192.168.8.249:8642/v1/chat/completions

ssh clinic-vps 'curl -s http://127.0.0.1:8088/api/agents/nephew-chat/status' | jq .tunnel
# "direct-url"
```

## Undo

```bash
ssh clinic-vps '
rm ~/.config/systemd/user/nephew-tower-api.service.d/direct-url.conf
systemctl --user daemon-reload
systemctl --user restart nephew-tower-api
'
```

Tower-api falls back to the SSH-tunnel path (which fails on the VPS, but returns a clean error rather than attempting an impossible config).
