# Chapter 25 — Cassette Update & Agent Paste Bridge (YSJ ↔ Nephew)

**Public-safe:** how infrastructure operators and agents route **"Update the Cassette"** work between **yousirjuan** (platform docs) and **nephew** (implementation + SOP).

---

## Chapter intents

| Intent | Why |
|---|---|
| **Two repos, one ritual** | Same operator phrase; different repo owns different layers |
| **No duplicate SOP** | Nephew `docs/sop/update-the-cassette.md` is canonical — YSJ links, does not fork |
| **Agent attach bundle** | Every chat gets the right paste without re-explaining the stack |
| **Infrastructure receipts** | Forge push, LaunchAgent, doors, mesh — YSJ documents *why*; Nephew ships *how* |

---

## Repo split (REPOS-CONTRACT)

| Topic | **yousirjuan** (this repo) | **nephew** (orchestrator repo) |
|---|---|---|
| Hardware / mesh / forge sync | ✅ Chapters 1–4, 7, 13, 18, 23 | Private runbooks only |
| Voice **architecture** (Holler vs Kokoro tiers) | ✅ Ch. 11, 10 | Engine code + `voice-config.json` |
| M5 edge **boot contract** | ✅ Document LaunchAgent once-per-Mac | Scripts: `m5-voice-edge-daemon.sh`, `install-m5-voice-launchagent.sh` |
| Pockit / door **vocabulary** | ✅ Ch. 15 | `family-tape-gateway`, `pockit.js`, manifests |
| **"Update the Cassette" SOP** | ✅ This chapter + ch. 8 ritual | ✅ `docs/sop/update-the-cassette.md` (canonical) |
| Cassette manifests / assembly line | ❌ Do not edit here | ✅ `cassettes/`, `make cassette-line` |
| Agent paste (full) | ✅ `docs/agent-pastes/infrastructure-operator-context.md` | ✅ `docs/agent-pastes/cassette-update-context.md` |
| Personas / soul / meta-library | ❌ Never | ✅ Nephew only |

---

## Operator phrase → which repo first

| Phrase | Start in | Then |
|---|---|---|
| **Update the Cassette** / **make vanilla** | Nephew checkout | `make cassette-line CHECK=<id>` |
| **Wire doors / make doors** | Nephew on operator Mac | `make doors` (sudo once) |
| **Voice sounds robotic / Holler down** | Nephew | `make voice-launchagent` · health curl |
| **Forge / GitHub mirror drift** | yousirjuan | `make forge-push` · ch. 23 |
| **Explain stack to family** | yousirjuan | `docs/setup/README.md` chapters 1–5 |
| **Enterprise agent on GitHub only** | GitHub `main` → Gitea sync | ch. 23 timer |

---

## Eight layers (nephew — replay from here)

When updating any manifest cassette (including **`voice`** Parakeet):

| # | Layer | Verify command |
|---|--------|----------------|
| 1 | Manifest | `cassettes/<cat>/<id>/cassette.json` |
| 2 | Registry | `make cassettes-discover` |
| 3 | Catalogue | `node scripts/build-cassette-catalogue.mjs` |
| 4 | Door | `make doors` |
| 5 | Framework | `node scripts/resolve-surface.mjs <id> --lineage` |
| 6 | Player UI | Pockit `#/c/<id>` or CT route |
| 7 | Mirror | WordPress: `make nephew-wp-sync` · voice: skip |
| 8 | Mac edge | Pockit.app: `make install-pockit-app` · voice: `make voice-launchagent` |

Bulk: `make cassette-patch CONSOLE=<console> APPLY=1`

Canonical playbook: `marvelousempire/nephew` → `docs/sop/update-the-cassette.md`

---

## Pattern E — Parakeet voice pad (shipped v1.79.42)

Infrastructure facts operators need without opening Nephew:

| Field | Value |
|---|---|
| Cassette id | `voice` |
| Operator URL | **`http://pockit.localhost/#/c/voice`** |
| M5 edge | STT `:8767` · Holler gateway `:7851` · backend `:8100` |
| Reboot-safe | LaunchAgent `ai.nephew.m5-voice-edge` via **`make voice-launchagent`** (once) |
| Assembly line | **`make cassette-line CHECK=voice`** — all gates green (2026-06-15) |
| Schema | `settings.surface` validates via `cassette-surface.schema.json` |

Nephew annex: `docs/pockit/Parakeet-Voice-Cassette-Vanilla.md`  
Plans: Nephew `0201`, `0202`

```bash
# From nephew repo on FIVEMAC
make cassette-line CHECK=voice
make ensure-voice
curl -s http://127.0.0.1:8088/api/v1/voice/health | jq '{route:.route_preferred,m5:.m5_edge.ok,engine:.m5_edge.tts.engine}'
```

Expect: `route: "m5"`, `m5: true`, `engine: "holler"` when LaunchAgent running.

---

## Elevations map (Family Office stack)

Cross-repo shipped vs queued — report ✅/⚠️/⬜ in handoffs:

### Shipped (voice + cassettes)

| ID | Elevation | Repo | Evidence |
|---|---|---|---|
| E-V1 | Voice cassette registered | nephew | `CHECK=voice` green |
| E-V2 | M5 Holler Auto routing | nephew | tower voice health |
| E-V3 | Reboot-safe LaunchAgent | nephew | `launchctl print …/m5-voice-edge` |
| E-V4 | Grok-bar prefetch UX | nephew | `voice-pad.js` |
| E-W1–W6 | WordPress/Pockit wiring | nephew | `WordPress-Cassette-Vanilla.md` |
| Forge automation | Gitea ↔ GitHub | **yousirjuan** | ch. 23, `make forge-push` |

### Queued (honest — do not fake live)

| ID | Elevation | Owner |
|---|---|---|
| E-V6 | F5 operator voice clone | nephew + boss `record-voice-ref.sh` |
| E-V7 | NeMo Riva GPU backend | nephew DGX |
| NAS Docker migration | WP/Matrix off DGX | nephew plan 0197 |
| Redis STM | Short-term voice memory | yousirjuan ch. 21 stub |
| Zero-trust Caddy mTLS | Replace gateway model | yousirjuan ch. 19 planning |

Full gap table: Nephew → `docs/agent-pastes/cassette-update-context.md` § Gaps filled

---

## Agent attach bundle (every chat)

### Universal (attach first)

| Priority | File | Repo |
|---|---|---|
| 1 | `docs/agent-pastes/infrastructure-operator-context.md` | **yousirjuan** |
| 2 | `docs/agent-pastes/cassette-update-context.md` | **nephew** |
| 3 | `docs/agent-pastes/agent-chat-attach-bundle.md` | **nephew** |

### By task type

| Task | Also attach |
|---|---|
| Voice / Parakeet / Goal 65 | Nephew `Parakeet-Voice-Cassette-Vanilla.md` |
| Doors / Pockit nav | YSJ ch. 15 + Nephew `Cassette-Surface-Taxonomy.md` |
| WordPress mirror | Nephew `WordPress-Cassette-Vanilla.md` |
| Matrix / Gitea embed | Nephew `Family-Office-Embed-Apps.md` |
| Forge / dual-remote | YSJ ch. 23 |

**Cursor opener (paste):**

```text
You-Sir Juan infrastructure mode. Read yousirjuan docs/agent-pastes/infrastructure-operator-context.md
and nephew docs/agent-pastes/cassette-update-context.md. REPOS-CONTRACT: infra here, orchestration in nephew.
When I say "Update the Cassette", run make cassette-line CHECK=<id> in nephew. Report pipeline stage with curl proof.
```

---

## After Nephew ships — YSJ maintenance ritual

When Nephew merges voice/cassette/door work:

1. Skim Nephew `CHANGELOG.md` top entry (version + verify block).
2. Update YSJ `docs/setup/` chapter if **architecture** changed (not every line of code).
3. Bump YSJ `docs/CHANGELOG.md`.
4. **`make forge-push`** from yousirjuan (Gitea master → GitHub mirror).
5. Do **not** copy Nephew manifests into yousirjuan — link only.

---

## Related

- [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md)
- [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md)
- [08-daily-operator-workflows.md](./08-daily-operator-workflows.md)
- [23-forge-sync-automation.md](./23-forge-sync-automation.md)
- `REPOS-CONTRACT.md`
- Nephew: `docs/sop/cassette-update-elevations.md`, Plan 0215
