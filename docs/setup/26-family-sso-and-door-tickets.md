# Chapter 26 — Family SSO & Door Tickets

**Public-safe:** how one family sign-in rides across Pockit doors — no live credentials or operator secrets.

---

## Chapter intents

| Intent | Why |
|---|---|
| **One sign-in** | Operators and family members authenticate once at the hub — not at every cassette door. |
| **Doors, not ports** | SSO flows through `*.localhost` names and tower-api — never teach `:8088` or `:5174` as operator URLs. |
| **Verified identity only** | Apps trust proxy headers from the gateway after tower-api validates the session — not browser-supplied spoof headers. |
| **Cross-door handoff** | Opening Hello (or any tape) in a new tab reuses the hub session via a short-lived door ticket. |
| **Replay on failure** | When SSO “doesn’t work,” check stack health before blaming passwords. |

---

## The model (one paragraph)

Everyone signs in once at the **family gate** (`tower-api` on the operator Mac or DGX). On local `*.localhost` doors the session cookie is **host-only** (browsers reject `Domain=.localhost`); on apex the cookie uses **`.jailynmarvin.com`**. When you open a different cassette door, the gateway either reads the cookie on the same host or hands off through **`door-ticket`** → **`door-redeem`**. Proxy-SSO apps (Grafana, WordPress behind the gateway, Open WebUI) receive verified **`X-Webauth-User`** / **`X-Webauth-Role`** headers from the gate — never from the browser alone.

**Canonical implementation:** `marvelousempire/nephew` → `docs/operator/family-sso.md`

---

## Operator flow

```text
1. Boot stack on operator Mac
      POCKIT_LOCAL_ONLY=1 make pockit    # local only — no apex deploy required
      make doors                         # once — clean http://pockit.localhost/

2. Sign in once
      http://pockit.localhost/signin
      Credentials: ~/.nephew/tower.env (NEPHEW_OPERATOR_*)
      NOT ReadyPlay Admin — family tower.env only

3. Open any console or tape
      make bishop · make clinic · http://hello.localhost/
      ↗ new tab → brief redirect through door-redeem → signed in

4. Verify honesty (optional)
      make sso-doctor    # in nephew checkout — spoof guard
```

---

## Door ticket handoff (cross-tab / cross-door)

When the hub session exists but a new door hostname needs its own cookie:

| Step | Endpoint | Result |
|---|---|---|
| Mint | `GET /api/v1/auth/door-ticket?target=<door URL>` | `{ ok, redeem_url, expires_in }` or `not_signed_in` |
| Redeem | `GET /api/v1/auth/door-redeem?ticket=…&target=…` on target door | Sets cookie on that door, redirects to tape |

Tickets are **90 seconds**, one-time, in-memory on tower-api.

**Alive vs broken:**

```bash
curl -s 'http://127.0.0.1:8088/api/v1/auth/door-ticket?target=http://hello.localhost/'
# logged out → {"ok":false,"error":"not_signed_in"}   ✓ route alive
# broken     → {"ok":false,"error":"not_found"}       ✗ tower-api stale — restart stack
# dead       → connection refused                     ✗ tower-api down — see recovery below
```

---

## What role each member gets (summary)

| App | Admin | Member |
|---|---|---|
| **Grafana** | Admin (auto) | Viewer (auto) |
| **WordPress** (`wordpress` door) | administrator | subscriber |
| **Open WebUI** (`hello`) | admin / approved | pending → one-time admin approval |
| **Control Tower / Pockit** | operator session | family-trust-users.json account |

Full table: nephew `docs/operator/family-sso.md`

---

## When SSO breaks — recovery (operator Mac)

**Clinic case (nephew):** `0013-family-sso-door-ticket-regression`  
**Replay playbook (yousirjuan):** [`ledger/LEDGER-0035-family-sso-infra-receipt/`](../ledger/LEDGER-0035-family-sso-infra-receipt/)

### Quick triage

```bash
lsof -nP -iTCP:8088,8781,8782 -sTCP:LISTEN
curl -s 'http://127.0.0.1:8088/healthz'
curl -s 'http://127.0.0.1:8088/api/v1/auth/door-ticket?target=http://hello.localhost/'
curl -s -o /dev/null -w '%{http_code}\n' 'http://pockit.localhost/signin'
```

| Symptom | Likely cause | Fix |
|---|---|---|
| Sign-in **502** / “tape not ready” | tape-server `:8781` or tower-api `:8088` dead | `POCKIT_LOCAL_ONLY=1 make pockit` |
| Second password on every door | Stale host-only cookie (pre–Domain=.localhost) | Clear `nephew_session` on all `*.localhost`; sign in again at hub |
| `invalid_credentials` | Wrong password family | Use `tower.env` creds — not ReadyPlay Admin |
| `door-ticket` **not_found** | tower-api not restarted after auth deploy | `make down && POCKIT_LOCAL_ONLY=1 make pockit` |
| `make pockit` fails on nephew-ct SSH | Apex ship preflight — not SSO itself | `POCKIT_LOCAL_ONLY=1 make pockit` for local work |

---

## Production apex (`jailynmarvin.com`)

- Sign in at the family apex once; cookie domain **`.jailynmarvin.com`** carries to subdomains.
- nginx `auth_request` → tower-api `/api/v1/auth/verify` on gated vhosts.
- Runbook: nephew `docs/runbooks/family-hub.md`

---

## What yousirjuan does NOT own

| Item | Owner repo |
|---|---|
| `door-tickets.js`, session cookie code | **nephew** `src/tower-api/auth/` |
| Pockit sign-in UI | **nephew** `containers/nephew-ct/family-hub/` |
| family-trust-users.json | **nephew** (gitignored on operator box) |

This chapter documents **operator behavior and verification** only.

---

## Related

- [08-daily-operator-workflows.md](./08-daily-operator-workflows.md) — boot + SSO smoke
- [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md) — door names
- [17-agents-fleet-bishop-cloak.md](./17-agents-fleet-bishop-cloak.md) — Bishop boot modes
- Nephew: `docs/operator/family-sso.md`, `docs/Issue-Log.md` (2026-06-13 SSO entry)
- Agent paste: [`docs/agent-pastes/family-sso-operator-context.md`](../agent-pastes/family-sso-operator-context.md)
