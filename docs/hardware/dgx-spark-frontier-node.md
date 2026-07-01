# DGX Spark (`nephew-spark`) — frontier compute node

**Status:** ✅ live-audited 2026-07-01 · The family's core AI runtime — "Nephew's body."
Parent: [`setup/01-hardware.md`](../setup/01-hardware.md) · **Vendor spec:** [`../hardware/dgx-spark-official-spec.md`](../hardware/dgx-spark-official-spec.md) · Inference floor: [`setup/31-m5-max-dgx-inference-setup.md`](../setup/31-m5-max-dgx-inference-setup.md)

---

## Compute

| Attribute | Verified value (2026-07-01) |
|---|---|
| **SoC** | NVIDIA **GB10 Grace Blackwell** superchip (SKU **940-54242-0000**) |
| **CPU** | **20-core Arm** — 10 **Cortex-X925** + 10 **Cortex-A725** (`aarch64`, Ubuntu LTS) |
| **GPU** | Blackwell (CUDA-native, `sm_121`) |
| **Memory** | **121 GB unified LPDDR5X** — one pool shared by CPU + GPU |
| **Memory bandwidth** | ~**273 GB/s** — the decisive fact: decode is **bandwidth-bound**, so a **MoE model (few active params) is far faster than a dense model** of the same total size (e.g. a 30B-A3B MoE ≫ a 32B dense) |

### What the bandwidth ceiling means for model choice
- **Prefer MoE / low-active-param** models for the daily driver (fast decode).
- **FP8 dense** is *slower* than **Q4** of the same model here (FP8 reads more bytes/token). Measured: `qwen2.5:32b` Q4 ≈ **72 tok/s** on GPU vs. a 32B-FP8 dense ≈ **~7 tok/s**.
- Keep only **one** large chat model GPU-resident (`OLLAMA_MAX_LOADED_MODELS=1`); summon heavy/escalation models on demand.

---

## Storage

| Attribute | Value |
|---|---|
| **Internal NVMe** | **3.7 TB** (Samsung MZALC4T0HBL1) — models, containers, hot Qdrant, gitea-data |
| **Expansion** | **2 empty internal M.2 Gen5 ×4 slots** (`0000:00`, `0002:00` — Presence-Detect negative). A Gen4 NVMe (e.g. a 990 Pro) here runs ~7 GB/s — **the fastest unused resource on the box** and the ideal model-weights hot tier |
| **Free** | ~2.6 TB free on `/` (2026-07-01) |

---

## Networking (the reality — corrects the old "2× 10GbE / 10GbE-to-NAS" claim)

| Interface | What it is | State |
|---|---|---|
| `enP7s7` | **1× 10 GbE RJ45** (Realtek 8127) | UP, but on a **dead point-to-point link** `10.77.0.2/30` (peer absent) — **effectively free** |
| `enx6c6e…` | **USB 1 GbE dongle** (Realtek 8153) | Carries the **LAN + NAS** traffic (`192.168.10.205`) — **the current bottleneck (~125 MB/s)** |
| `wlP9s9` | MediaTek 7925 WiFi | down |
| WG | WireGuard mesh | `10.1.0.5` |

- **No Thunderbolt** — USB-C ports are **USB 3.2 Gen 2×2 (20 Gbps)**. TB devices don't tunnel PCIe here.
- **No ConnectX / QSFP** — `lspci` shows zero Mellanox/NVIDIA network devices; the box has a single RJ45 10 GbE, not the dual-QSFP ConnectX some DGX Spark configs ship.
- **10 GbE plan:** cable `enP7s7` directly to the NAS's 10 GbE RJ45 (point-to-point `/30`), remount NFS over it → ~1.25 GB/s (10× today). Only one 10 GbE port, so it's NAS-direct or a 10 GbE switch — not both plus another link.

---

## What runs here

Production LLM serving (Ollama + vLLM), the RAG retrieval rack (bge-m3 embeddings `:9200`, bge-reranker-v2-m3 `:9201`, Qdrant `:6333`, `tower-api /api/v1/retrieve`), voice STT/TTS containers, the Gitea Family Forge + act_runners, Matrix/Synapse, and the Docker fleet. See [`setup/03-software-services.md`](../setup/03-software-services.md).

### Model-serving notes
- **vLLM** serves HF-format weights (safetensors) — the path for a fast MoE daily driver (`qwen3-coder-30b-a3b`) + **EAGLE-3 / P-EAGLE speculative decode** (vLLM ≥ 0.16; pre-trained draft available for Qwen3-Coder-30B). Ollama loads that same MoE **CPU-only** on the GB10, so vLLM is the route for it.
- **Reranker:** keep the pool small (16) and the model warm — a 32-passage pool soft-times-out (>3.5s) on this box.

---

## Access

- SSH alias `nephew-spark`; WG `10.1.0.5`; headless console via the **Comet GL-RM10RC KVM**.
- Gitea Family Forge at `10.1.0.5:2424` (repos under `~/gitea-data`).

---

## Related

- [`setup/01-hardware.md`](../setup/01-hardware.md) — full roster
- [`setup/31-m5-max-dgx-inference-setup.md`](../setup/31-m5-max-dgx-inference-setup.md) — inference floor + quantization
- [`setup/16-knowledge-fabric-rag-quantization.md`](../setup/16-knowledge-fabric-rag-quantization.md) — RAG rack
- Nephew `deploy/dgx/serve-qwen3-coder-vllm.sh` — the MoE + P-EAGLE serving script
