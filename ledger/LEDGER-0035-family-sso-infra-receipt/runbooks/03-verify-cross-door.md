# Runbook 03 — Verify cross-door SSO

After hub sign-in:

1. Open **`http://hello.localhost/`** (or click ↗ from Pockit grid) — should **not** ask for password again.
2. Open **`make bishop`** door — factory intention loads inside Pockit skin.
3. Optional: `make sso-doctor` from nephew checkout (spoof guard).

## Failure modes

| Behavior | Next step |
|---|---|
| Second password on hello only | Clear cookies; confirm Domain=.localhost on session cookie |
| 401 on sign-in | Wrong password family — tower.env not ReadyPlay Admin |
| Blank / connection refused | `make family-status` or triage runbook 01 |
