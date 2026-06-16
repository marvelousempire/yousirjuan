# Chapter 27 — Cassette Factory and brain proxy

**Public-safe** · Plan 0230/0231 · **Last updated:** 2026-06-16

---

## One-button GitHub → family surface

| Who | How |
|-----|-----|
| **Family** | **Cassette Factory.app** or `http://cassette-factory.localhost/` → paste GitHub URL → **Install & Boot** |
| **Agents** | `make cassette-from URL=https://github.com/OWNER/REPO` |

Both call the same pipeline: mirror to Gitea forge → classify archetype → scaffold cassette → **brain merge** → DGX bootstrap → `make cassette-line`.

---

## NEPHEW_BRAIN_PROXY (required)

Every factory cassette env overlay includes:

```bash
NEPHEW_BRAIN_PROXY=http://10.1.0.5:8088
NEPHEW_EGRESS_DENY=1
```

**Meaning:** chat, tools, and agent loops route through **tower-api → Hermes** on DGX — never a second cloud LLM stack inside the cassette container.

Factory **blocks** vendor compose that bundles standalone Ollama/vLLM without this proxy (anti-collision gate).

---

## Archetypes

| Archetype | Door after install | Done tile |
|-----------|-------------------|-----------|
| `web-ui` | `http://{slug}.localhost/` | Open Door + Open {Name}.app |
| `headless-fleet` | _(dark)_ | Open Control Tower |
| `channel` | _(dark)_ | Open CT → channels |
| `embed` | Pockit `#/c/{id}` | Open in Pockit |

Fleet-owned (do not re-factory): Hermes, tower-api, doc-rag, OpenClaw, Ollama, Qdrant.

---

## Brain merge (automatic)

On every install:

- Registry + catalogue + passport stub
- `docs/pockit/<Name>-Cassette.md`
- Optional MCP registry row
- Docker runtime export + Dockyard labels
- Sovereign egress scan (Plan 0231)
- Best-effort vault sync + corpus index

---

## Verify

```bash
# Nephew repo
make cassette-from URL=https://github.com/owner/repo   # dry-run first with --dry-run on script
make cassette-line CHECK=web-odysseus
make sovereign-egress-audit
```

Full pipeline doc: Nephew `docs/pockit/Cassette-Factory-Pipeline.md` · SOP `docs/sop/github-link-to-cassette.md`.
