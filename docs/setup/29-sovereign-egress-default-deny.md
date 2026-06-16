# Chapter 29 — Sovereign egress (default deny)

**Public-safe** · Plan 0231 · **ONLY PRIVATE**

---

## The rule

> If a component phones home to external LLM, analytics, or unknown HTTPS APIs — **block it** or **move inference to Family Office hardware**.

Default **deny**. Allow only:

- Loopback + WireGuard mesh (`10.1.0.*`)
- Family LAN (`192.168.10.*`)
- Self-hosted forge (`git.jailynmarvin.com`)
- In-cluster names (`tower-api`, `ollama`, `qdrant`, `chromadb`)

---

## Enforcement layers

| Layer | What |
|-------|------|
| **Network** | Plan 0180 bind law — services on `127.0.0.1` + `10.1.0.5`, not `0.0.0.0` |
| **Brain proxy** | `NEPHEW_BRAIN_PROXY=http://10.1.0.5:8088` on every factory cassette |
| **Factory gate** | Brain merge fails on cloud URLs in deploy overlays |
| **Assembly line** | `make cassette-line` includes sovereign egress for docker cassettes |
| **Fleet audit** | `make sovereign-egress-audit` scans Odysseus, Hermes, Ollama, OpenClaw, voice, RAG |

---

## Tool audit order

1. **Odysseus** — overlay env uses DGX embed/rerank; upstream vendor may list cloud providers in code — overlays win at runtime
2. **OpenClaw** — must route into tower/Hermes (L5), not parallel cloud stack
3. **Ollama** — local inference only; model **pulls** are one-time bootstrap (pre-cache via warmer)
4. **Hermes / tower-api / RAG** — bge-m3 + reranker on DGX; `/api/v1/retrieve` never calls OpenAI

```bash
cd ~/Sites/nephew   # or ~/Developer/nephew on DGX
make sovereign-egress-audit
node scripts/audit-fleet-egress.mjs --tool=odysseus
node scripts/audit-fleet-egress.mjs --tool=ollama --strict-vendor   # optional upstream deep scan
```

---

## Odysseus RAG (sovereign)

Personal Chroma on host; embeddings from DGX bge-m3; rerank via tower-api — see Nephew `deploy/odysseus/nephew-dgx.env.example`.

---

## Related

- Nephew `docs/pockit/Sovereign-Egress-Gate.md`
- Nephew `docs/sovereign.md`
- [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md)
- AISL skill `sovereign-egress-default-deny`
