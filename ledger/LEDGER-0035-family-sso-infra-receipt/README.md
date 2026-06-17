# LEDGER-0035 — Family SSO infra receipt (verify, do not implement)

**What:** Replay-only playbook when operators report “SSO not working” on the Family Office Mac stack.  
**Why:** SSO requires **tower-api :8088** + **gateway :8782** + **tape-server :8781** alive; partial stacks produce 502 sign-in and login loops.  
**Code owner:** `marvelousempire/nephew` — this ledger does not patch auth routes.

## Architecture (public-safe)

```text
Browser → http://pockit.localhost/signin
              ↓
       family-tape-gateway :8782
              ↓
       tape-server :8781  →  /api/*  →  tower-api :8088
              ↓
       Session cookie Domain=.localhost
              ↓
       Other doors (hello.localhost, bishop.localhost, …)
              ↓ optional
       door-ticket → door-redeem (90s one-time handoff)
```

## Operator order

1. [runbooks/01-triage-stack.md](runbooks/01-triage-stack.md) — ports + curl probes
2. [runbooks/02-recover-local-stack.md](runbooks/02-recover-local-stack.md) — boot + cookie clear
3. [runbooks/03-verify-cross-door.md](runbooks/03-verify-cross-door.md) — hub sign-in + tape open

## Replay

```bash
bash ledger/LEDGER-0035-family-sso-infra-receipt/playbooks/sso-smoke.sh
```

## Status

`shipped` — documentation + smoke script (2026-06-16). Nephew auth implementation remains in nephew repo.

## Related

- Nephew: `docs/operator/family-sso.md`, Issue-Log 2026-06-13
- YSJ: `docs/setup/26-family-sso-and-door-tickets.md`
- Plan: `plans/0005-nephew-platform-sync-receipt.md`
