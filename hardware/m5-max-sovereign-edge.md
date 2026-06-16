# M5 Max — sovereign edge node

**Hardware mesh entry** · full operator chapter: [`docs/setup/10-m5-max-sovereign-edge.md`](../docs/setup/10-m5-max-sovereign-edge.md)

| Component | Spec | Notes |
|-----------|------|-------|
| Chip | Apple M5 Max | ANE + unified memory for edge voice |
| Role | **Sovereign edge** | Dev, Pockit doors, Holler TTS, faster-whisper STT, Obsidian Visual vault |
| Brain | DGX Spark `nephew-spark` | Heavy inference, Qdrant, Hermes, fleet RAG |
| WireGuard | `10.1.0.x` peer | Required for DGX services when off LAN |

## Capability matrix

| Capability | Status | Notes |
|------------|--------|-------|
| Pockit + doors | ✅ Full | `make pockit` / `make quick` |
| Parakeet voice pad | ✅ Full | Holler premium · `make cassette-line CHECK=voice` |
| Fleet RAG query | ✅ Via tunnel/LAN | tower-api `:8088` · `nephew_corpus_retrieve` |
| DGX GPU inference | ✅ Remote | Never cloud LLM for core |
| Cassette Factory wizard | ✅ Full | Mac `.app` + `:8797` |

## Ready-to-paste env (edge dev)

```bash
NEPHEW_BRAIN_PROXY=http://10.1.0.5:8088
NEPHEW_EGRESS_DENY=1
NEPHEW_EMBEDDINGS_URL=http://10.1.0.5:9200
NEPHEW_RERANKER_URL=http://10.1.0.5:9201
M5_HOLLER_PORT=8100
```

Sync script: `hardware/sync-hardware-md.js` — add this file to the mesh index when editing specs.
