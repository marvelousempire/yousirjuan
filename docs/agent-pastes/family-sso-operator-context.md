# Family SSO operator context — paste block (You-Sir Juan)

Prepend when debugging **“SSO not working”**, second login prompts, or door handoff failures across Pockit doors.

Canonical implementation: **`marvelousempire/nephew`** → `docs/operator/family-sso.md`  
Setup chapter: **`docs/setup/26-family-sso-and-door-tickets.md`**

---

## One sentence

Sign in **once** at `http://pockit.localhost/signin` with **`~/.nephew/tower.env`** credentials; session cookie **`Domain=.localhost`** rides to every door; cross-tab opens use **`door-ticket`** → **`door-redeem`**.

---

## Alive check (30 seconds)

```bash
lsof -nP -iTCP:8088,8781,8782 -sTCP:LISTEN
curl -s 'http://127.0.0.1:8088/healthz'
curl -s 'http://127.0.0.1:8088/api/v1/auth/door-ticket?target=http://hello.localhost/'
# expect not_signed_in when logged out — NOT not_found, NOT connection refused
```

---

## Recovery (operator Mac)

```bash
POCKIT_LOCAL_ONLY=1 make pockit    # local stack — skips nephew-ct deploy
make doors                         # once per Mac — clean URLs
# Browser: clear nephew_session on *.localhost → sign in at hub again
```

---

## Common mistakes

| Mistake | Symptom |
|---|---|
| ReadyPlay Admin password | 401 invalid_credentials |
| tower-api down (`:8088`) | sign-in 502, door-ticket refused |
| Stale host-only cookie | signed in on one door only |
| Raw `:5174` / `:8088` URLs taught to operator | bypasses door + cookie domain |

---

## Boss Moves (ONLY YOU)

1. Confirm `~/.nephew/tower.env` operator email/password (not committed).
2. Browser: clear cookies + one hub sign-in after stack restart.
3. `make sso-doctor` from nephew checkout when changing auth code.

---

## Cross-repo

| Fix code / routes | **nephew** |
| Explain + verify | **yousirjuan** ch. 26 + LEDGER-0035 |
| Ledger replay | `ledger/LEDGER-0035-family-sso-infra-receipt/` |
