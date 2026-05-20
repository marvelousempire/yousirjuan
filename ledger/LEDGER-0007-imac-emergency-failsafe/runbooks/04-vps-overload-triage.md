# Runbook 04 — VPS overload triage (sshd starved, kernel still alive)

When the VPS feels "down" but isn't actually down. This is the most common failure mode we've seen — sshd, nginx, and GitLab all stop responding from outside, but the host kernel is still routing packets. The cause is almost always a runaway userspace process eating all CPU.

## How to recognize this signature

From the iMac (or any client), run these in order:

```bash
ping -c 3 -W 2 72.167.151.251 && \
ssh -o BatchMode=yes -o ConnectTimeout=5 -vv vps-godaddy 'uptime' 2>&1 | \
  grep -E "established|banner|Permission|refused|timed"
```

| What you see | What it means | Action |
|---|---|---|
| `0% packet loss` + `Connection established` + `timed out during banner exchange` | **Overload** — sshd accepted the TCP socket but is too starved to write its `SSH-2.0-…` greeting back | This runbook |
| `100% packet loss` | Network / host down | Different runbook (not yet written — GoDaddy panel reboot) |
| `Connection refused` (RST at SYN) | sshd not running, OR fail2ban banned your IP | Different runbook (not yet written) |
| `Permission denied (publickey)` after established | sshd is fine; auth problem | [LEDGER-0003 runbook 04](../../LEDGER-0003-vscode-remote-vps/runbooks/04-troubleshoot-refused-connections.md) |

**Do not retry SSH in a loop.** Repeated half-handshakes can trip the `sshd-ddos` fail2ban jail (a separate jail from `sshd`), and you'll lock yourself out of a perfectly-good sshd once it recovers. Diagnose via the GoDaddy console instead.

## Get in via the out-of-band console (sshd-independent)

GoDaddy's VPS panel exposes a browser-based KVM console. It speaks directly to the VM's serial / virtual TTY — completely independent of sshd, nginx, the network stack, and any userspace daemon.

1. Browser: https://account.godaddy.com/products
2. Find the VPS line ("yousirjuan VPS" or similar) → **Manage**.
3. In the VPS dashboard, **Console** (sometimes labeled "VNC" or "Web Terminal").
4. The console loads in a new tab. Log in at the TTY prompt with the VPS root or `abrownsanta` credentials (password, not SSH key — the console doesn't honor key auth).

You're now in. Move to triage.

## Triage on the box (run these in order)

```bash
# 1. Confirm it's really overloaded
uptime
# Look for load average: anything >> #CPUs is genuine overload.
# This VPS has 4 vCPUs, so load >4 is concerning, load >10 is bad, load >30 is what we've seen.

# 2. Who's eating CPU?
top -bn1 -o %CPU | head -20
# Look at the top 5 processes by %CPU. Note any with command containing:
#   - rg, ripgrep, fd, find        (filesystem scans — common Cursor / VS Code remote-server symptom)
#   - node, .vscode-server, .cursor-server  (remote IDE backends)
#   - gitlab-puma, sidekiq, gitaly  (GitLab internals — legitimate but tunable)
#   - postgres, redis              (data services — restart-as-last-resort)

# 3. Who's eating memory?
free -h
top -bn1 -o %MEM | head -20

# 4. Disk full? (causes lots of weird cascading failures)
df -h /
# If / is >90% full, that's likely the proximate cause.
```

## Most-likely culprits we've seen, in order

### Cursor / VS Code remote-server scanning `/`

Symptom: a `rg` or `node` process owned by your user is pinned at 100% CPU. `top` shows the cmdline includes `.cursor-server` or `.vscode-server`.

Cause: someone opened the editor's "Open Folder" at `/` (filesystem root) instead of `/home/abrownsanta` or a specific repo. ripgrep then tries to index the entire filesystem (`/proc`, `/sys`, every container layer, every git pack file).

Fix:

```bash
# Kill the runaway scan. Adjust user if not abrownsanta.
pkill -u abrownsanta -f '\.cursor-server' ; \
pkill -u abrownsanta -f '\.vscode-server' ; \
pkill -u abrownsanta -f 'rg --json'

# Watch load drop
watch -n 2 uptime    # Ctrl-C when load < 4
```

Then **don't open a remote folder at `/` again.** Always pick `/home/abrownsanta` or a specific repo path.

### GitLab Puma/Sidekiq runaway

Symptom: one of `gitlab-puma`, `sidekiq`, `gitaly` pinned. Often coincides with a CI run, a big push, or a webhook storm.

Fix (try in order, gentlest first):

```bash
# 1. Throttle GitLab — restart only the bloated component
sudo gitlab-ctl restart puma         # most common
# OR
sudo gitlab-ctl restart sidekiq

# 2. If load doesn't drop in 60s, restart the whole stack
sudo gitlab-ctl restart

# 3. If even gitlab-ctl is unresponsive, the supervisor itself is starved.
#    Last resort:
sudo systemctl restart gitlab-runsvdir
```

### Out-of-memory thrash

Symptom: `free -h` shows `available` < 200 MB. Swap is 100% used. `dmesg | tail -50` shows `oom-killer invoked`. Load is high not because of CPU but because every process is waiting on swap.

Fix:

```bash
# Identify the memory hog
ps aux --sort=-%mem | head -10

# Kill it (if safe)
sudo kill -TERM <pid>

# If it won't die in 10s, escalate
sudo kill -KILL <pid>
```

Don't `swapoff -a` to "fix" swap thrash — that immediately OOMs whatever was leaning on swap, often including sshd. Just kill the offender.

### Disk full

Symptom: `df -h /` shows 100%. Anything that writes (logs, postgres WAL, GitLab) is now wedged.

Fix:

```bash
# Find the biggest directories
sudo du -sh /var/log /var/lib/docker /var/opt/gitlab /home/*  2>/dev/null | sort -h

# Common culprits:
sudo journalctl --vacuum-time=7d       # systemd journal — often hundreds of MB
sudo docker system prune -af           # docker layers + stopped containers
sudo apt-get clean                     # apt cache
```

## After the load drops

```bash
# Verify recovery from the iMac
ssh -o ConnectTimeout=5 vps-godaddy 'uptime ; ps aux | wc -l'

# Verify HTTPS surfaces
for sub in hello nephew clinic git workflow; do
  printf '%-10s ' "$sub"
  curl -s -o /dev/null -w '%{http_code}\n' -m 6 "https://${sub}.yousirjuan.ai/"
done
```

Watchdog state should re-converge automatically on the next tick. To force a tick immediately without waiting 3 min:

```bash
launchctl kickstart -k gui/$(id -u)/com.yousirjuan.vps-watchdog
sleep 5
bash ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh status
```

## Postmortem capture

If the same culprit shows up twice, codify it. Each recurring overload deserves either:

- a **ledger entry** with a playbook that prevents the cause (e.g. an MOTD warning not to open `/` in remote editors), or
- a **pain-journal entry** (`pain-journal/PAIN-NNNN.md`) describing the recurring frustration.

The watchdog log itself is a primary source — `grep WOULD ~/Library/Logs/yousirjuan-vps-watchdog.log` shows every near-swap event historically, which is a free overload-frequency timeline.

## Related

- [02-watchdog-design.md](02-watchdog-design.md) — the state machine that fires during these events.
- [03-enabling-real-swap.md](03-enabling-real-swap.md) — what happens differently when DRY_RUN=0.
- [LEDGER-0003 runbook 04](../../LEDGER-0003-vscode-remote-vps/runbooks/04-troubleshoot-refused-connections.md) — refused-connection patterns (different signature from overload).
