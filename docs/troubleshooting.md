# Troubleshooting

Common issues + how to fix them. Add new entries as we hit them.

## Quick diagnostic

Always start with:
```bash
bash tools/health.sh           # status table for everything
bash tools/health.sh --infer   # also runs a real Ollama round-trip
```

Exit 0 = everything critical is OK. Exit 1 = at least one critical thing is broken (the table tells you which).

## Symptoms → fixes

### `openclaw: command not found`
The `~/.npm-global/bin` PATH entry isn't in this shell yet.
```bash
source ~/.zshrc       # macOS / zsh
source ~/.bashrc      # most Linux / bash
# or just open a new terminal tab
```

### Open WebUI shows no models in the dropdown
Container can't reach Ollama. Verify:
```bash
# On the host:
ss -tlnp | grep 11434              # or: lsof -nP -iTCP:11434 -sTCP:LISTEN
# Should show *:11434 (i.e. 0.0.0.0).
# If it shows 127.0.0.1 only, the container can't reach it.
```

Fix:
- **Linux**: `sudo systemctl edit ollama` → add `Environment="OLLAMA_HOST=0.0.0.0:11434"` → `sudo systemctl restart ollama`
- **macOS**: `launchctl setenv OLLAMA_HOST "0.0.0.0:11434"` → `brew services restart ollama`

### Open WebUI loads, you log in, but the page is blank / API calls return 401
You probably have nginx basic auth in front of it. Open WebUI uses `Authorization: Bearer` for its post-login API calls; the browser drops basic-auth headers when there's a Bearer token, so nginx 401s every API call.

Fix: **remove basic auth** from the nginx vhost (Open WebUI's own login is the auth gate). See `vps/nginx-vhost.conf.template` — it intentionally has no `auth_basic`.

### `Could not find a production build in the .next directory` (PM2 errors for a Next.js app)
Not an AI-stack issue, but common when something else on the VPS dies during the OOM cascade. Rebuild:
```bash
cd /opt/<your-app>
npm run build
pm2 restart <app-name>
```

If `npm run build` itself fails with "DATABASE_URL not set" or similar — your build needs env vars. Use `dotenvx` or PM2's `--env` flag.

### VPS is slow / unresponsive / SSH times out
Likely OOM cascade. Causes I've seen:
- Ollama loaded a model that needed more RAM than was free
- Too many Docker containers all spiked at once
- Build process eating RAM

Check from outside:
```bash
ping -c 3 <your-vps-ip>      # should respond if kernel alive
ssh <vps>                    # if this hangs, system is in trouble
```

If SSH times out: **reboot from the hosting provider's panel** (GoDaddy → Servers → your VPS → Restart). Everything systemd-managed (nginx, Postgres, Docker, Ollama, fail2ban, Tailscale) auto-restarts on boot.

**Prevention** (already done):
- `/swapfile` 4 GB enabled — see `vm.swappiness=10`
- Ollama configured `OLLAMA_KEEP_ALIVE=5m`, `OLLAMA_MAX_LOADED_MODELS=1` — releases memory when idle

### VPS SSH says `Connection refused` even though `ssh.service` is active

This means the SSH key is not the first problem. TCP is being refused before
authentication. On the GoDaddy VPS, the working recovery was to bypass port `22`
and disable socket activation so `sshd` binds directly to an alternate port.

In the provider Recovery Console:

```bash
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
echo Port 2222 | sudo tee /etc/ssh/sshd_config.d/99-alt-port.conf
sudo systemctl restart ssh
sudo ss -ltnp | grep 2222
sudo iptables -I INPUT 1 -p tcp --dport 2222 -j ACCEPT
sudo systemctl disable --now ssh.socket
sudo systemctl restart ssh
sudo ss -ltnp | grep ssh
```

Proof of recovery:

```text
0.0.0.0:2222 users:(("sshd",...))
[::]:2222    users:(("sshd",...))
```

Then connect from the Mac:

```bash
ssh clinic-vps
```

Why this works: `ssh.socket` can keep systemd socket activation in control of
the listener. Disabling it makes `ssh.service` own the configured `Port 2222`
listener directly.

Self-heal before changing keys:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=10 clinic-vps true
nc -vz -w 5 72.167.151.251 2222
nc -vz -w 5 72.167.151.251 22
cd /Users/nivram/Developer/nephew && node bin/nephew gitlab status
```

If `clinic-vps` works and `2222` is open, SSH is healthy. A refused `22` is
expected and means the caller is using the legacy route. If `2222` is refused,
return to the provider Recovery Console and repeat the socket/firewall recovery
above. If the error is `Permission denied`, repair `authorized_keys` instead of
changing ports.

### Public site returns HTTP 502 but loopback works
nginx is up, app is down. Check:
```bash
ss -tlnp | grep <app-port>      # is the app listening?
pm2 list                         # if PM2-managed, what's its state?
docker ps --filter name=<x>     # if Docker-managed
```
Restart the app:
```bash
pm2 restart <app-name>
docker restart <container-name>
```

### Public HTTPS cert expired
Certbot has a built-in renewal timer (`systemctl status certbot.timer`). If it broke:
```bash
sudo certbot renew
sudo systemctl reload nginx
```

### macOS firewall popup never appeared / got dismissed
Reset and let it re-prompt:
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --remove /usr/local/bin/ollama 2>/dev/null
brew services restart ollama
```

### MagicDNS hostnames don't resolve (`vps-godaddy: nodename nor servname provided`)
Tailscale was started with `--accept-dns=false`. Re-up:
```bash
tailscale up --accept-dns=true
```

### Tailnet-only ping works but `ssh vps-godaddy` hangs
Probably the SSH config doesn't have a `Host vps-godaddy.<tailnet>.ts.net` entry. Either:
```bash
ssh vps-godaddy.tailaa31dd.ts.net      # explicit FQDN
```
Or add to `~/.ssh/config`:
```
Host vps-godaddy
    HostName vps-godaddy.tailaa31dd.ts.net
    User abrownsanta
```

### OpenClaw gateway won't start (Linux: `systemctl status openclaw-gateway`)
Look at the actual error:
```bash
sudo journalctl -u openclaw-gateway --since '5 min ago' | tail -30
tail -30 ~/.openclaw/logs/gateway.err.log
```

Common issues:
- **`Cannot find module 'typebox/build/index.mjs'`** — re-run the installer; it auto-patches this. If it doesn't:
  ```bash
  cd /tmp && npm init -y && npm install --no-save typebox@1.1.33
  cp -R node_modules/typebox/build/. ~/.npm-global/lib/node_modules/openclaw/node_modules/typebox/build/
  cp -R node_modules/typebox/build/. ~/.npm-global/lib/node_modules/openclaw/dist/extensions/google/node_modules/typebox/build/
  ```
- **`EADDRINUSE :18789`** — something else on the port: `ss -tlnp | grep 18789` then kill it
- **`Model context window too small`** — your default model has <16k context, OpenClaw's minimum. Switch to a model with more context, or change `models.providers.ollama.models[N].contextWindow` in `~/.openclaw/openclaw.json`.

### Inference times out / is unbearably slow
Most likely: CPU-only inference on a busy machine. Check:
```bash
ollama ps                  # what's loaded?
top -o %CPU | head -10     # what's eating CPU?
```

For a usable agent experience, you really want **Apple Silicon (Metal GPU) or NVIDIA GPU**. CPU-only Ollama is fine for the occasional simple chat; not for OpenClaw's heavy prompts.

If the VPS is your only option, use a **smaller model** (gemma2:2b, phi3) and keep prompts short.

### Disk full / "no space left on device"
```bash
df -h /                    # check disk usage
docker system df           # what Docker is hoarding
docker system prune -af    # nuke unused images/containers/networks (keeps named volumes)
ollama rm <unused-models>  # free model storage
```

### "I can't reach `hello.yousirjuan.ai` from my phone but it works from my laptop"
Cellular DNS lag. Cell carrier's DNS resolvers are slow to update.
- Disable mobile data, switch to wifi → try
- Or change DNS on phone to 1.1.1.1 (iOS: Settings → Wi-Fi → ⓘ → Configure DNS → Manual)
- Wait 30 min and retry

### Forgot Open WebUI admin password
SSH to the VPS, reset the bcrypt password directly in SQLite:

```bash
docker exec -it open-webui python3 -c "
import sqlite3, bcrypt
new_pass = b'mynewpassword'
hashed = bcrypt.hashpw(new_pass, bcrypt.gensalt()).decode()
con = sqlite3.connect('/app/backend/data/webui.db')
con.execute('UPDATE auth SET password = ? WHERE email = ?', (hashed, 'YOUR_EMAIL@here.com'))
con.commit()
print('done')
"
```

Then sign in with the new password.

### "I want to start over from scratch"
```bash
bash tools/uninstall.sh --all     # nuclear: removes everything including chat history
bash bootstrap.sh                 # fresh install
```

(Or restore from a backup: `bash tools/restore.sh <path>`.)

## Logs to know

| What | Where |
|---|---|
| Open WebUI app | `docker logs open-webui` |
| Ollama | `journalctl -u ollama` (Linux) / `tail -f /tmp/ollama.log` (macOS) |
| OpenClaw gateway | `~/.openclaw/logs/gateway.log` + `gateway.err.log` |
| nginx | `/var/log/nginx/access.log` + `error.log` |
| fail2ban bans | `sudo fail2ban-client status sshd` |
| install.sh / linux.sh / macos.sh | `~/private-ai-install.log` or `~/yousirjuan-install.log` |
| iptables current rules | `sudo iptables -S` + `sudo iptables -S DOCKER-USER` |
| systemd unit status | `systemctl status <unit>` |
