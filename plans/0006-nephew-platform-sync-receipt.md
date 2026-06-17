Status: living — append when Nephew ships platform-facing plans

# Plan 0006 — Nephew platform sync receipt (YSJ doc updates)

## Context

You-Sir Juan documents **infrastructure and operator behavior**; Nephew ships **Pockit, cassettes, tower-api, SSO**. When Nephew lands substantive platform plans, this plan records which YSJ surfaces to update so agents do not re-discover gaps.

Boundary: `REPOS-CONTRACT.md` — no Nephew code in yousirjuan.

## Sync table

| Nephew plan / ship | YSJ surfaces to touch |
|---|---|
| **0195** Bishop-optional boot | ch. 17 (Bishop two-mode table) |
| **0198** Bishop factory player | ch. 17 (hosted cassettes, `make bishop`) |
| **0196** Pockit universal HUD | ch. 12 (re-skin / `pockit_hud` embed) |
| **Family SSO door-ticket** (v1.79.2+) | ch. 26 (new), ch. 08 smoke, agent paste, LEDGER-0035 |
| **Console shorthands** (`make bishop`, `make pocket`) | ch. 08 boot table |
| **agent-comms / relay** (0175–0178) | ch. 08 or ch. 25 (when operator-facing) |
| **WordPress family SSO** (0200) | ch. 18 OIDC table + ch. 26 proxy-SSO row |

## Ritual after Nephew merge

1. Skim Nephew `CHANGELOG.md` for operator-visible auth/Pockit/Bishop rows.
2. Update matching `docs/setup/` chapter(s) — **describe and verify**, do not fork code.
3. Bump `docs/CHANGELOG.md` here.
4. Update `docs/Feature Ledger.md` status rows.
5. **`make forge-push`** — Gitea master first.

## Verification

- `grep -l '0195\|0198\|door-ticket' docs/setup/*.md` shows expected chapters.
- Agent pastes cross-link without duplicating Nephew SOP bodies.

## Out of scope

- Editing `cassette-catalogue.json`, tower-api routes, or Pockit JS in this repo.
