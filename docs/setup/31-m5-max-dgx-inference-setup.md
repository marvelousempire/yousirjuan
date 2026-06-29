# Chapter 31 — M5 Max + DGX Inference Floor (Hardware · Quantization · Mac-First Routing)

**Public-safe** · the hardware + inference-runtime floor under the Super Rick stack: the two compute nodes, the inference software each runs, how work routes between them, and how we *measure* a model before trusting it.

**Canonical technical copy (mirrored):** `marvelousempire/standard-voice-stack` → `understandings/M5-MAX-DGX-INFERENCE-SETUP.md`
**Runtime owner:** `marvelousempire/nephew` → `~/.zshrc` `OLLAMA_HOST`, `~/.hermes/config.yaml`, `scripts/lib/hybrid-brain-env.sh`

Complements [Chapter 10 — M5 Max sovereign edge](./10-m5-max-sovereign-edge.md), [Chapter 16 — Knowledge fabric, RAG & quantization](./16-knowledge-fabric-rag-quantization.md), [Chapter 24 — ANE voice optimization](./24-apple-neural-engine-voice-optimization.md), and [Chapter 30 — Voice full undressing](./30-voice-stack-full-undressing.md). Mesh addressing lives in [Chapter 18 — WireGuard matrix](./18-wireguard-matrix-nas-gitea-why.md).

---

## 1. Two nodes, one principle

Inference runs on **Family Office hardware only** — never cloud. The work splits across two machines:

| Node | Role | Why |
|------|------|-----|
| **MacBook Pro M5 Max** | **edge / primary heavy-lifter** | 128 GB unified memory — not memory-starved; does the daily heavy lifting |
| **DGX Spark (GB10)** | **always-on brain / fallback** | NVIDIA CUDA + vLLM for FP8/AWQ; the lane the Mac can't run |

**Mac-first, DGX-fallback** is the standing rule: use the Mac unless it can't, then fall to the DGX.

---

## 2. Hardware spec sheets (verified)

**M5 Max** (read live from `system_profiler`):

| Spec | Value |
|------|-------|
| Chip | Apple M5 Max |
| Unified memory | 128 GB |
| GPU cores | 40 |
| CPU cores | 18 (6 + 12) |

**DGX Spark:**

| Spec | Value |
|------|-------|
| Platform | NVIDIA DGX Spark — Grace Blackwell GB10 |
| Unified pool | 121 GB (single GB10 pool) |
| Reach | SSH alias `nephew-spark`, over the WireGuard mesh (ch. 18) |

---

## 3. Inference software per node

| Node | Stack | Format |
|------|-------|--------|
| **M5 Max** | **Ollama** (llama.cpp + Metal) · **MLX** (Apple-native, optional) | **GGUF** · MLX 4/8-bit |
| **DGX Spark** | **vLLM-GB10** · Ollama | **FP8 / AWQ** · GGUF |

The voice pipeline's brains — `nephew:fast` (Ollama) and `nephew:prime` (Qwen3-32B-FP8 on vLLM) — are documented in [Chapter 30](./30-voice-stack-full-undressing.md). This chapter is the runtime floor beneath them.

---

## 4. Quantization follows the hardware

The single most-confused point. **The quant format is chosen by the silicon, not by preference.**

| Format | Built for | Runs on |
|--------|-----------|---------|
| **GGUF** (Q4_K_M / Q5_K_M / Q6_K / Q8_0) | llama.cpp + Metal | **the Mac** |
| **MLX** (4-bit / 8-bit) | Apple GPU/ANE — often faster than GGUF on Mac | **the Mac** |
| **AWQ / GPTQ / FP8** | NVIDIA CUDA + vLLM | **the DGX** |

- **AWQ/GPTQ do not run on the Mac** via Ollama — they're CUDA/vLLM formats; AWQ's home is the DGX. On the Mac it's GGUF or MLX.
- **128 GB changes the math:** Mac quantization is about **speed, not capacity**. A 32B's default GGUF is Q4_K_M (~19 GB); with 128 GB you can run **Q6_K** or **Q8_0** (near-lossless, ~35 GB) — the only cost is tokens/sec.

See [Chapter 16](./16-knowledge-fabric-rag-quantization.md) for the corpus/RAG side of quantization.

---

## 5. Mac-first routing

The control point is the `OLLAMA_HOST` environment variable. The shell picks the node by **capability**: if the Mac's local Ollama is serving, use it; otherwise fall back to the DGX over the mesh. (A previous config hard-pinned everything to the DGX — that's been replaced with the capability check.)

| Failover | Covered? |
|----------|----------|
| Mac Ollama down → DGX | ✅ shell capability check |
| Mac busy/OOM mid-request → DGX (load-based) | ⬜ local router shim — planned |

Addressing for the mesh lives in [Chapter 18](./18-wireguard-matrix-nas-gitea-why.md); the public-safe tree does not carry the IPs.

---

## 6. The local agent (Nous Hermes) vs the voice brain

`ollama launch hermes` installs the **Nous Research Hermes Agent** to `~/.hermes` — a tool-using developer/agent TUI. It is **not** the voice pipeline's `hermes-bridge` (same word, different layer). Its brain runs on the Mac:

| Requirement | Setting |
|-------------|---------|
| Runs locally | `base_url` → the Mac's Ollama |
| Tool-capable model | `qwen2.5:32b` (reasoning-only models like DeepSeek-R1 reject tools) |
| Context | `context_length: 65536` (Hermes needs ≥ 64 K) |

**Privacy:** private *as configured* (model stays on Family Office hardware). Not automatically "100%": the picker's `:cloud` models and outbound skills (browser, mail, messaging) leave the box. Private = local/DGX model + no cloud skills.

---

## 7. Weigh & measure — evidence, not assertion

Model/quant choices are measured, not guessed (Super Rick: *Configuration Rigor*). The harness `standard-voice-stack/tools/weigh-and-measure.sh` reports, per model: **tool-call acceptance · context window · time-to-first-token · tokens/sec**, and writes a receipt — so "best brain on the Mac" is a number, not an opinion. Two hard gates for an agent brain: tools = yes, context ≥ 64 K.

---

## 8. NAS model cache — pull once, sync forever (never re-download)

Models are a Family Office asset. A model the family already owns on its own hardware is **synced over the LAN, never re-downloaded from the internet** (`family-model-cache-no-redownload`, RL-MODELCACHE-001).

- **The vault:** the NAS holds the family model registry at `<nas>/ai-models/` — `ollama/` (Ollama store shape: `manifests/` + `blobs/`) and `huggingface/`. As of June 2026 it carries the whole fleet (`qwen3-coder:30b`, `qwen2.5:*`, `nephew:*`, `llama3.3:70b`, …). Addressing is in [Chapter 18](./18-wireguard-matrix-nas-gitea-why.md); on the Mac it mounts under the `media` share.
- **The lookup order (every acquisition):** local → **NAS** → peer node (DGX) → internet (**last resort, then back-populate the NAS**). Run `make model-ensure MODEL=<m>`, never a bare `ollama pull`.
- **The guardrail:** inference **never** runs off NAS-mounted weights (a multi-GB model over SMB crawls). The NAS is a cache you **sync *from*** onto fast local storage; Ollama serves from local. Never point `OLLAMA_MODELS` at the NAS.
- **Per node:** each machine mounts the vault and `model-ensure` rsyncs only the blobs it's missing — so a new node gets a 30 GB model from the NAS over the LAN in minutes, not from the registry.

| Piece | Where |
|-------|-------|
| Rule | `nephew/.claude/rules/family-model-cache-no-redownload.md` |
| Tool | `nephew/scripts/ollama-model-cache.sh` (`ensure`/`push`/`pull-nas`/`list-nas`/`status`) · `make model-ensure` |
| Mac mount | `nephew/data/nas-mac-mounts.json` (`media` share → vault under `ai-models/`) |
| Vault pin | `NEPHEW_MODEL_CACHE_NAS=<mount>/ai-models/ollama` |

---

## Related

- [Chapter 10 — M5 Max sovereign edge](./10-m5-max-sovereign-edge.md) · [Chapter 16 — RAG & quantization](./16-knowledge-fabric-rag-quantization.md) · [Chapter 18 — WireGuard matrix](./18-wireguard-matrix-nas-gitea-why.md) · [Chapter 30 — Voice full undressing](./30-voice-stack-full-undressing.md)
- Canonical: `marvelousempire/standard-voice-stack` → `understandings/M5-MAX-DGX-INFERENCE-SETUP.md`
