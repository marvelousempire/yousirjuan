---
name: wireguard-only-no-tailscale
id: RL-WIREGUARD-ONLY-001
keywords: [wireguard, vpn, remote-access, tailscale, sovereign-network]
goal: Keep every operator-owned private-network path on self-controlled WireGuard and fail closed on Tailscale suggestions or dependencies.
---

# WireGuard only — never Tailscale

## Permanent operator instruction

> “I dont want to use ever - Tailscale. Only Wireguard.” — 2026-06-11

## Rule

- Private links between operator-owned machines use WireGuard. Never propose, install, enable, depend on, or repair Tailscale, Tailnet, MagicDNS, Funnel, or DERP.
- Before networking advice or mutation, read the current wiring/ledger and inspect the actual WireGuard path. Do not substitute a generic VPN recommendation.
- `10.1.0.0/24` is the live Family Office WireGuard mesh unless a newer authoritative inventory says otherwise; DGX is `10.1.0.5`, VPS is `10.1.0.2`.
- Public services use the governed VPS TLS/auth edge and then WireGuard to private services. Public exposure is not a reason to add a third-party tunnel.
- Historical Tailscale material remains evidence, not permission. If an old ledger or tool registry conflicts, this rule supersedes it.
- A detected Tailscale package, daemon, interface, hostname, ACL, or dependency is configuration drift: report it, replace its consumers with WireGuard, verify, and remove it with operator authority.

## Agent preflight

For remote access, VPN, DNS, SSH, proxy, CI runner, or fleet routing work, search for `WireGuard`, `wg0`, and the canonical wiring before recommending anything. The words “Tailscale” or “Tailnet” in a proposal are a hard-stop unless documenting historical removal.

## Why

WireGuard is self-controlled, already deployed across the Family Office, and avoids third-party identity, coordination, relay, MagicDNS, and Funnel dependencies. The rule was preserved in Historia but not elevated into You-Sir Juan’s tool-neutral agent entrypoint, allowing stale “approved” records to outrank the operator’s later permanent decision.
