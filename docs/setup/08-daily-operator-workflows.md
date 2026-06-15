# Chapter 8 — Daily Operator Workflows

**Public-safe:** commands and rituals without live URLs or port numbers.

---

## Fresh machine bootstrap

```bash
# 1. Clone platform repo
git clone https://github.com/marvelousempire/yousirjuan
cd yousirjuan
git submodule update --init --recursive
bash tools/init-client-assistant.sh

# 2. Clone orchestrator (required for Pockit, MCP, fleet make targets)
git clone https://github.com/marvelousempire/nephew
cd nephew
make hooks          # git secret guards
npm install         # nephew CLI + MCP deps
```

Join WireGuard mesh and configure SSH before expecting any internal service to respond.

---

## Session opener (agents & operators)

```bash
git worktree list
git fetch && git status
git log origin/main..HEAD --oneline
# Skim last entries in docs/Issue-Log.md (nephew or yousirjuan)
```

Agents: call `nephew_session_load` with session topic first.

---

## Study the product stack

```bash
cd nephew && node bin/nephew study
```

Or read `docs/product-stack-glossary.md` — Pockit version, cassette vocabulary, manifest map.

---

## Boot family surfaces (operator Mac)

| Goal | Command |
|---|---|
| Pockit player shell | `make pockit` |
| Full family stack on DGX | SSH to spark → `make family` |
| Clean door URLs (once, sudo) | `make doors` |
| Browse cassette library | `make door` |
| Boot one cassette | `make up <id>` |
| Console shorthand | `make bishop`, `make clinic`, … |
| Visual Obsidian vault | `make visual-obsidian` |
| NAS mounts | `make nas-mounts` |

Door URLs use `http://<id>.localhost/` form — tell operators the name, not gateway ports (canonical door URL rule).

---

## Cassette update ritual

When operator says **"Update the Cassette"** or **make vanilla**:

1. Read `docs/sop/update-the-cassette.md`
2. Run `make cassette-line CHECK=<id>`
3. For embed apps: `docs/pockit/Family-Office-Embed-Apps.md`

---

## Infrastructure doctor

| Check | Command |
|---|---|
| Nephew full verify | `make nephew-verify` |
| Automata-style doctor | `node scripts/doctor.mjs` (per repo) |
| Orchestra status | `node scripts/orchestra-doctor.mjs` |
| Doors live | `node scripts/verify-doors-live.mjs` |
| Cassette player matrix | `node scripts/audit-cassette-player-matrix.mjs` |

---

## RAG & corpus

| Task | Command |
|---|---|
| Agent retrieve | MCP `nephew_corpus_retrieve` |
| Reindex corpus (DGX) | `scripts/index-corpus.mjs` |
| Fleet brain refresh | `scripts/fleet-refresh-brain.sh` |
| Vault knowledge sync | `make` targets / `scripts/sync-vault-agent-knowledge.mjs` |

---

## Git day-to-day

```bash
# Push to forge (direct)
git push gitea feature/my-branch

# Push to GitHub (after PR)
git push origin feature/my-branch

# Open PR
gh pr create --title "..." --body "..."
```

Stage by explicit path only. Update CHANGELOG + Feature Ledger when shipping visible changes.

---

## Deploy after merge

From operator Mac (not from inside a dying worktree):

```bash
cd /path/to/main/nephew/checkout
git pull origin main
make deploy-<surface>    # backend, family-pockit, wp, etc.
# Smoke: curl public apex or run verify script
```

Name pipeline stage when reporting: committed / pushed / PR'd / merged / deployed / live.

---

## Visual checklist (plan tracking)

When tracking multi-phase work in plans or handoffs:

- Status icons: ✅ ⚠️ ❌ ⬜
- Lead with count: "Out of N phases: X ✅, Y ⚠️, Z ⬜"
- **Boss Moves** list = sudo, keys, browser human test, physical actions only

---

## Where to log lessons

| Event | Log |
|---|---|
| Shipped user-visible change | `docs/CHANGELOG.md` |
| Feature status change | `docs/Feature Ledger.md` |
| Bottleneck / near-miss | `docs/Issue-Log.md` |
| Teaching worth keeping | meta-library via `nephew_memory_write` |

---

## Boss Moves (operator-only)

1. WireGuard peer approval and key distribution for new devices  
2. `make doors` sudo on each operator Mac  
3. Verizon / router port-forward for WireGuard (see private ledger)  
4. Browser verification of family apex and Pockit after deploy  
5. NAS mount / Historia volume present before vault scripts  

---

## Related

- [README.md](./README.md) — master index
- [07-git-and-deploy.md](./07-git-and-deploy.md) — full ship cycle
- `marvelousempire/nephew` → `docs/ONBOARDING_FOR_NEXT_AI.md` — agent landing
- `marvelousempire/nephew` → `docs/handoffs/session-resume.md` — paste block for new chats
