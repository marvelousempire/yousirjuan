# Runbook 03 — Tailscale ACL for port 9876

The state server binds to `0.0.0.0:9876`. Without an ACL, anything on the tailnet can reach it. With an ACL, only tagged nodes can.

## Recommended ACL fragment

Add to your Tailscale account's ACL JSON (https://login.tailscale.com/admin/acls):

```json
{
  "tagOwners": {
    "tag:imac-watchdog": ["autogroup:admin"],
    "tag:nephew-tower":  ["autogroup:admin"],
    "tag:dustpan":       ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src":    ["tag:nephew-tower", "tag:dustpan"],
      "dst":    ["tag:imac-watchdog:9876"]
    }
  ]
}
```

Then in the Tailscale admin UI, tag your machines:

- iMac (the one running the state server) → `tag:imac-watchdog`
- VPS (running nephew control-tower) → `tag:nephew-tower`
- Any Mac running DustPan → `tag:dustpan`

## Verify

```bash
# From VPS:
ssh vps-godaddy 'curl -sf -m 3 http://imac-avery:9876/health && echo "ACL OK"'

# From an untagged machine on the tailnet:
tailscale ssh some-other-node 'curl -sf -m 3 http://imac-avery:9876/health || echo "blocked, as expected"'
```

## Caveats

- The `:9876` clause restricts by destination port. If you change `WATCHDOG_PORT` in the plist, update the ACL too.
- ACLs in Tailscale apply at the network layer — they do not replace the bearer token on POST. Both layers protect different things.

## Related

- [01-architecture.md](01-architecture.md) — endpoint spec.
- [02-install.md](02-install.md) — install procedure.
