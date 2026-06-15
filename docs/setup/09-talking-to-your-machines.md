# Chapter 9 — Talking to Your Machines

**Public-safe:** how the operator and family reach every layer of the stack — without live addresses or credentials.

---

## The communication layers

You do not have one channel — you have **stacked surfaces**, each tuned for a job:

| Layer | You use it to… | Typical entry |
|---|---|---|
| **SSH** | Shell on DGX, VPS, NAS; deploy, docker, logs | Host aliases in `~/.ssh/config` |
| **Door URLs** | Browser apps by name | `http://<cassette-id>.localhost/` after doors bootstrap |
| **tower-api** | Chat, voice STT/TTS, RAG retrieve, auth | Local API on operator Mac (proxies to DGX when needed) |
| **Pockit** | Family grid, Parakeet voice pad, suite bar | `make pockit` → `http://pockit.localhost/` |
| **Control Tower** | Operator dashboard, hello chat, ecosystem | CT door or suite bar jump |
| **Visual Obsidian** | Sovereign wiki, graphs, tasks, canvases | `make visual-obsidian` → **Visual-Home** vault |
| **Jarvis (voice)** | Talk-and-reply — **not** Obsidian commands | Pockit `#/c/voice` or iMessage bridge |
| **Cursor / Claude Code** | Agent dev with CLOAK MCP | `nephew` MCP + `.cursor/rules/` |
| **CLI `bin/nephew`** | Study, hermes chat, dispatch, witness | `node bin/nephew study` |
| **WireGuard** | Reach home services from away | Travel router or phone WG client |
| **Apple hands-on** | Open Obsidian, Shortcuts, UI automation | `make bootstrap-obsidian`, recipe catalog |
| **iMessage / Telegram** | Async family chat with Nephew soul | Bridges on DGX polling local chat DB |

**Naming lock:** **Visual** = Obsidian wiki. **Jarvis** = voice lane only. Do not say “open Jarvis” when you mean Obsidian.

---

## SSH fleet (machine-to-machine)

Each machine has a **role alias** — not a bag of IP addresses:

| Alias role | Machine | Use for |
|---|---|---|
| `nephew-spark` / `dgx` | DGX Spark | Docker fleet, Ollama, Gitea compute, voice containers |
| `nephew-ct` / `clinic-vps` | VPS edge | Clinic, public nginx, edge deploy |
| `gitea-dgx` | Git forge | `git push` over SSH to self-hosted forge |
| Operator Mac | FIVEMAC / twomac | Pockit gateway, M5 voice edge, Cursor |

Keys live in macOS Keychain (`UseKeychain yes`). Non-interactive deploy assumes WG or LAN path is up.

**Rule:** edit git-tracked composes on the box **after** pulling the same commit you edited locally — never drift the live DGX from a stale checkout.

---

## Doors — how browsers find services

Doors are **hostname routing** on the operator Mac:

1. `make doors` once (sudo) — port-80 forwarder for clean URLs  
2. Gateway routes `http://<id>.localhost/` → correct cassette backend  
3. Family sees names, not implementation ports  

Primary doors (operator vocabulary):

| Door | What opens |
|---|---|
| `pockit.localhost` | Family player console |
| `web-jarvis-sovereign.localhost` | Jarvis Sovereign hub cassette |
| `web-jarvis-mindspace.localhost` | MindSpace 3D child |
| `ext-vault.localhost` / `jarvis.localhost` | Quartz vault publish |
| `hello.localhost` | Hello chat tape |
| `voice.localhost` | Voice cassette door (primary UX is Pockit `#/c/voice`) |
| `gitea.localhost` | Git forge web UI |

Debug ports stay in private runbooks — operators should not need them day-to-day.

---

## tower-api — the API you actually talk through

On the operator Mac, **tower-api** is the front door for:

- `/api/v1/chat/*` — LLM turns (Hermes / Ollama on DGX)  
- `/api/v1/voice/*` — STT upload, TTS stream, health, engine routing  
- `/api/v1/retrieve` — RAG for agents and voice context  
- `/api/v1/auth/*` — family sign-in, OIDC for embed apps  

Pockit **voice-pad.js** and Control Tower hello chat call these routes — they do not hit raw container endpoints directly.

**Voice routing headers:** `X-Voice-Route` (auto / m5 / dgx), `X-Voice-Fast` for low-latency M5 path.

---

## Cursor / Claude / MCP

Agents load **CLOAK** via `nephew` MCP (28 tools). Session ritual:

1. `nephew_session_load` with topic  
2. Read `AI_AGENT_RULES/manifest.json`  
3. `nephew_corpus_retrieve` before substantive work  
4. `nephew_witness_add` + checkpoint on delivery  

`.cursor/rules/` carries Nephew law (door URL copy, dev discipline, visual-obsidian hands-free, quality bar).

---

## Visual Obsidian (rich human + agent wiki)

| Step | Command / action |
|---|---|
| Mount NAS Historia volume | `make nas-mounts` |
| Bootstrap vault + golden profile | `make visual-obsidian` or `make visual-obsidian-full` |
| Canonical home note | **Visual-Home.md** (not retired Jarvis-Home) |
| Golden profile in git | `data/obsidian-golden-profile/` — theme, plugins, snippets |
| Agent knowledge sync | vault sync scripts pump rules, plans, orchestra status |

Obsidian is the **richest** front-end — graphs, Dataview HUD, LiveSync (when wired), orchestra canvas.

---

## Apple hands-on agent (Plan 0198)

Layers A–E for macOS automation without manual clicking:

| Layer | Capability |
|---|---|
| A | Golden profile apply, community plugins |
| B | `open -a Obsidian`, `obsidian://` URIs |
| C | Terminal / Chrome automation AppleScripts |
| D | System Events UI (TCC-gated) |
| E | Shortcuts.app (`Nephew Visual Obsidian Setup`) |

Recipe catalog: `applescripts/catalog.json` in nephew repo.

Preflight: `make preflight-apple` · orchestra: `make orchestra-doctor`

---

## Async messaging (iMessage / Telegram)

Hermes runtime on DGX loads `data/nephew-soul.md` as system prompt. Bridges poll local message DB or gateway, forward to DGX chat completions, optionally synthesize voice reply (premium TTS path — see chapter 11).

---

## Operator quick matrix

| I want to… | Do this |
|---|---|
| Shell the DGX | `ssh nephew-spark` |
| Boot family UI | `make pockit` |
| Talk voice Jarvis | Pockit → Apps → Voice (Parakeet) |
| Edit wiki sovereign | `make visual-obsidian` |
| Agent session | Cursor + nephew MCP, or `node bin/nephew study` |
| Push code | `git push gitea` (forge) → mirrors to GitHub |
| Probe whole stack | `make orchestra-doctor` |
| Voice health | tower-api voice health endpoint (via local proxy) |

---

## Related

- [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) — M5 personal Jarvis layer  
- [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md) — how talk-back sounds  
- [12-pockit-non-vanilla-surfaces.md](./12-pockit-non-vanilla-surfaces.md) — UI synthesis  
- Nephew: `docs/runbooks/jarvis-sovereign-stack.md`, `docs/runbooks/apple-hands-on-agent.md`
