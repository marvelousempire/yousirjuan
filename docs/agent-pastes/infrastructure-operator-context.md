# Infrastructure operator context — paste block (You-Sir Juan)

Prepend when an agent lands in **yousirjuan** or when the operator asks about **hardware, mesh, forge, or platform setup** alongside Nephew work.

Hand-maintained · Nephew product paste: `marvelousempire/nephew` → `docs/agent-pastes/cassette-update-context.md`

---

## What this repo is

**You-Sir Juan** = private AI **infrastructure platform** (hardware, network, deployment, ledger runbooks).  
**Nephew** = orchestration + Pockit + cassettes + voice implementation + CLOAK.

Boundary: `REPOS-CONTRACT.md` — **no personas, no meta-library, no cassette.json edits in yousirjuan.**

---

## Current truth (2026-06-15)

| Track | Value |
|---|---|
| **YSJ docs** | `docs/setup/` chapters 0–25 — public-safe operator reference |
| **Nephew monorepo** | v1.79.42 · voice `CHECK=voice` green · Holler M5 edge reboot-safe |
| **Forge** | Gitea master on DGX → GitHub mirror · **`make forge-push`** before reporting done |
| **Operator Mac** | FIVEMAC · Pockit `http://pockit.localhost/` · Parakeet `http://pockit.localhost/#/c/voice` |
| **Doors** | `http://<id>.localhost/` after `make doors` — never teach `:8782` to humans |

---

## Stack elevations (read top → bottom)

```text
E0  Operator Mac     doors · Pockit.app · M5 voice LaunchAgent · Cursor
E1  Cassette gateway family-tape-gateway · tape-door-registry
E2  Players          Pockit · CT · WordPress theme
E3  DGX Spark        tower-api · Ollama · Qdrant · family stack
E4  NAS              Historia · WP files · git objects · docker stacks
E5  VPS edge         Public TLS gate only
```

Detail: [`docs/setup/README.md`](../setup/README.md) · voice: ch. 11 · doors: ch. 15 · cassette bridge: ch. 25

---

## Cross-repo routing

| Operator wants… | Work in | Key command / doc |
|---|---|---|
| Update cassette / make vanilla | **nephew** | `make cassette-line CHECK=<id>` · `docs/sop/update-the-cassette.md` |
| Parakeet voice / Holler edge | **nephew** | `make voice-launchagent` · `CHECK=voice` · ch. 11 (YSJ) for architecture |
| Explain family stack | **yousirjuan** | `docs/setup/README.md` |
| Sync git remotes | **yousirjuan** | `make forge-push` · ch. 23 |
| Replay infra task | **yousirjuan** | `ledger/LEDGER-NNNN-*/` |
| Agent retrieve / RAG | **nephew** | MCP `nephew_corpus_retrieve` · domains `["vault"]` |
| Skills pack edit | **ai-skills-library** | `skills/yousirjuan/<id>/SKILL.md` — never `skills/project/yousirjuan/` |

---

## Session opener (infrastructure agent)

```bash
cd ~/Sites/yousirjuan   # or ~/Developer/yousirjuan
git fetch && git status
cat docs/setup/README.md | head -40
make forge-status       # optional — Gitea vs GitHub drift
```

If task touches Pockit/cassettes/voice:

```bash
cd ~/Sites/nephew
make cassette-line CHECK=voice    # example
node bin/nephew study             # product vocabulary
```

Nephew session: call **`nephew_session_load`** first when MCP configured.

---

## Ship discipline (both repos)

1. Stage by **explicit path** — never `git add -A`.
2. Update **CHANGELOG** in the repo you changed.
3. **yousirjuan:** `make forge-push` before reporting done (Gitea master).
4. **nephew:** push Gitea origin + GitHub mirror per parallel-git rule.
5. Name **pipeline stage:** committed / pushed / PR'd / merged / deployed / **live** (curl proof).

---

## Attach with (cassette / voice chats)

Always pair this paste with Nephew:

1. `nephew/docs/agent-pastes/cassette-update-context.md`
2. For voice: `nephew/docs/pockit/Parakeet-Voice-Cassette-Vanilla.md`
3. YSJ bridge: [`docs/setup/25-cassette-update-agent-bridge.md`](../setup/25-cassette-update-agent-bridge.md)

---

## Boss Moves (operator only)

- `make doors` (sudo)
- `make voice-launchagent` (once per Mac)
- WireGuard peer approval
- Browser smoke on Pockit / Parakeet after deploy
- Forge credentials / Gitea admin on DGX

---

## Forbidden

- Editing `cassette.json` or Nephew manifests from yousirjuan sessions
- Copying long Nephew SOP bodies into yousirjuan (link instead)
- Persona / soul / meta-library content in yousirjuan PRs (CI blocks)
- Reporting "live" without curl or health JSON proof
