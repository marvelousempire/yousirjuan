# Chapter 26 — Family SSO and door tickets

**Public-safe** · mirrors Nephew family door auth · **Last updated:** 2026-06-16

---

## One sign-in, many doors

| Surface | URL | Auth |
|---------|-----|------|
| Family hub / Pockit | `http://pockit.localhost/` | Master Key SSO via tower-api |
| Cassette doors | `http://<slug>.localhost/` | Door ticket handoff from hub |
| Control Tower | `http://nephew.localhost/` or DGX `:5174` | Same SSO session |
| Odysseus | `http://odysseus.localhost/` | Master Key cross-door (see Nephew Clinic 0021) |

**Canonical rule:** tell operators **`http://<id>.localhost/`** — not gateway port `:8782` (debug only).

---

## How door tickets work

1. Operator signs in at hub (Master Key or OIDC family provider).
2. tower-api issues a short-lived **door ticket** cookie scoped to the target cassette.
3. Family tape gateway (`scripts/family-tape-gateway.mjs`) validates ticket before proxying to backend.
4. Cross-door (e.g. CT → Odysseus) uses the same ticket chain — no second login when SSO is healthy.

---

## Recovery when SSO breaks

| Symptom | Fix |
|---------|-----|
| Door 302 loop | `make doors` · verify tower-api `:8088` · `scripts/oidc-client-add.mjs` heal |
| Odysseus incognito only | See Nephew `docs/operator/odysseus-sso.md` · `make odysseus-sso-configure` |
| Master Key rejected | `docs/operator/nephew-master-key-sso.md` · check `src/tower-api/auth/master-key.js` |

---

## Nephew owns implementation

Scripts, routes, and manifests live in **`marvelousempire/nephew`**. You-Sir Juan documents the operator contract only.

Verify: `make doors-verify` · `make smoke-hello-entry-points` (Nephew repo).
