# Runbook 03 — Enabling real DNS swaps (the go-live checklist)

DRY_RUN=1 is safe; DRY_RUN=0 makes real DNS changes the moment a target fails 3 ticks. Don't flip it until every box below is checked.

## The checklist

| # | Check | How to verify |
|---|---|---|
| 1 | GoDaddy API key + secret stashed at `~/.config/yousirjuan/godaddy.env` (chmod 600) | `ls -la ~/.config/yousirjuan/godaddy.env` shows `-rw-------` |
| 2 | `godaddy-dns.sh get` works for a known subdomain | `bash playbooks/godaddy-dns.sh get yousirjuan.ai hello` prints the current IP |
| 3 | TTL pre-lowered to 60s on every failover-eligible subdomain | `dig +noall +answer +nocomments hello.yousirjuan.ai` shows TTL ≤ 60 (give it the original TTL to expire first) |
| 4 | iMac is publicly reachable at `FAILOVER_IP` (Tailscale Funnel running, or router port-forward, etc.) | `curl -sI https://<FAILOVER_IP>/ ` from a non-tailnet machine returns something (200 / 401 / 4xx — anything from the iMac itself) |
| 5 | Each subdomain in `TARGETS` has a STANDBY container running on the iMac that serves the right content | `docker ps` on iMac shows containers; tested via Host header or via the iMac's local IP |
| 6 | Watchdog has been running in DRY_RUN for at least 24h with no spurious swap-decisions in the log | `grep "WOULD SWAP\|WOULD REVERT" ~/Library/Logs/yousirjuan-vps-watchdog.log` shows only expected entries |
| 7 | Operator has read [02-watchdog-design.md](02-watchdog-design.md) and understands the state machine | self-attested |

**If any line is "no," stop. Going live without these is the careless thing the contracts-and-prudence rule forbids.**

## Going live

```bash
# 1. Edit the watchdog script:
sed -i.bak 's/^DRY_RUN="${DRY_RUN:-1}"/DRY_RUN="${DRY_RUN:-0}"/' \
  ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/vps-watchdog.sh

# 2. Set FAILOVER_IP to the iMac's public-reachable address:
#    Edit the FAILOVER_IP line in vps-watchdog.sh.
#    For Tailscale Funnel: get the IP via `tailscale funnel status`
#    For port-forward: use the operator's home WAN IP (visible via curl ifconfig.me)

# 3. Restart the launchd job so the change takes effect:
launchctl unload ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist
launchctl load -w ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist

# 4. Verify next tick is live (not dry-run):
sleep 5
tail -5 ~/Library/Logs/yousirjuan-vps-watchdog.log
# Should see: ── live tick (DRY_RUN=0; real GoDaddy API calls enabled)
```

## Validating end-to-end without breaking production

Run one controlled test before relying on it:

1. Pick ONE low-impact subdomain (e.g., `hello.yousirjuan.ai`).
2. Temporarily edit the watchdog's `TARGETS` so `hello`'s probe URL is `https://hello.yousirjuan.ai/this-path-doesnt-exist-and-returns-502` (or use a server you control to return 502).

   Actually simpler: temporarily flip the probe URL to `https://72.167.151.251:99999/` — port 99999 is invalid; connection-refused → 000 → DOWN.

3. Wait 9–10 min for three ticks. Watchdog should:
   - Log 3 strikes for `hello`.
   - Call GoDaddy API to set `hello.yousirjuan.ai` → `FAILOVER_IP`.
   - Subsequent `dig hello.yousirjuan.ai` returns the new IP (after TTL expiry).
4. Verify clients now hit the iMac standby for `hello`.
5. Revert the probe URL change.
6. Wait 9–10 min for three successes. Watchdog reverts the DNS.
7. Verify `dig` shows the VPS IP again.

If this end-to-end test passes, the watchdog is trustworthy.

## Rolling back to DRY_RUN

```bash
sed -i.bak 's/^DRY_RUN="${DRY_RUN:-0}"/DRY_RUN="${DRY_RUN:-1}"/' \
  ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/vps-watchdog.sh
launchctl unload ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist
launchctl load -w ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist
```

The watchdog stops calling GoDaddy. **Any subdomains currently swapped to FAILOVER stay there** until manually reverted via `bash playbooks/godaddy-dns.sh set yousirjuan.ai <sub> 72.167.151.251 600` for each.

## Emergency manual override

If the watchdog flips DNS unexpectedly and you need to force-revert ALL subdomains back to VPS right now:

```bash
for sub in hello nephew clinic git workflow; do
  bash ~/Developer/yousirjuan/ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/godaddy-dns.sh \
    set yousirjuan.ai "$sub" 72.167.151.251 600
done
```

Then disable the watchdog to prevent it firing again until you've diagnosed:

```bash
launchctl unload ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist
```

## Related

- [01-godaddy-api-credentials.md](01-godaddy-api-credentials.md), [02-watchdog-design.md](02-watchdog-design.md)
- Repo rule: [`.claude/rules/contracts-and-prudence.md`](../../../.claude/rules/contracts-and-prudence.md) — careful before live, prudence over speed.
