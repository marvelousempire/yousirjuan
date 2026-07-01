# DGX Spark (`nephew-spark`) — frontier compute node

**Status:** ✅ live-audited 2026-07-01 · The family's core AI runtime — "Nephew's body."
Parent: [`setup/01-hardware.md`](../setup/01-hardware.md) · **Vendor spec:** [`../hardware/dgx-spark-official-spec.md`](../hardware/dgx-spark-official-spec.md) · Inference floor: [`setup/31-m5-max-dgx-inference-setup.md`](../setup/31-m5-max-dgx-inference-setup.md)

---

## Compute

| Attribute | Official spec (NVIDIA datasheet) + live probe |
|---|---|
| **SoC** | NVIDIA **GB10 Grace Blackwell** superchip (product `940-54242-0000`) |
| **CPU** | **20-core Arm — 10× Cortex-X925 + 10× Cortex-A725** (`aarch64`) |
| **GPU** | **Blackwell** (CUDA-native, `sm_121`) — 5th-gen Tensor Cores, 4th-gen RT Cores; **up to 1 PFLOP FP4** (sparsity); 1× NVENC / 1× NVDEC |
| **Memory** | **128 GB LPDDR5x** unified, coherent, **256-bit** @ 4266 MHz (**121 GB usable** in the OS) |
| **Memory bandwidth** | **273 GB/s** — the decisive fact: decode is **bandwidth-bound**, so a **MoE model (few active params) is far faster than a dense model** of the same total size (e.g. a 30B-A3B MoE ≫ a 32B dense) |
| **Power / TDP** | 240 W PSU (USB-C PD 48V/5A); GB10 chip TDP 140 W |
| **Size / weight** | 150 × 150 × 50.5 mm · 1.2 kg |
| **OS** | NVIDIA DGX OS (Ubuntu-based, aarch64) |

### What the bandwidth ceiling means for model choice
- **Prefer MoE / low-active-param** models for the daily driver (fast decode).
- **FP8 dense** is *slower* than **Q4** of the same model here (FP8 reads more bytes/token). Measured: `qwen2.5:32b` Q4 ≈ **72 tok/s** on GPU vs. a 32B-FP8 dense ≈ **~7 tok/s**.
- Keep only **one** large chat model GPU-resident (`OLLAMA_MAX_LOADED_MODELS=1`); summon heavy/escalation models on demand.

---

## Storage

| Attribute | Value |
|---|---|
| **Internal NVMe** | **4 TB NVMe M.2, self-encrypting** (spec) — the OS reports ~3.7 TB usable (Samsung MZALC4T0HBL1); holds models, containers, hot Qdrant, gitea-data |
| **Expansion** | **None documented** — the single M.2 slot holds the 4 TB drive; NVIDIA lists **no spare M.2 / storage-expansion slot**. *(Correction: an earlier draft wrongly read two idle internal PCIe root ports as "empty M.2 slots" — they are not user-accessible storage slots. The 990 Pros stay in the Mac Thunderbolt enclosures.)* |
| **Free** | ~2.6 TB free on `/` (2026-07-01) |

---

## Rear panel — the full port map (NVIDIA datasheet)

| Port | Spec |
|---|---|
| **4× USB Type-C** | Leftmost = **power in, 240 W PD** (48V/5A). The other **3 = 20 Gb/s data** (USB 3.2 Gen2×2) **+ DisplayPort alt-mode → up to 3× DP displays**. **Not Thunderbolt** — the DGX has no TB controller |
| **1× HDMI 2.1a** | Display out + HDMI multichannel audio |
| **1× RJ-45, 10 GbE** | The general ethernet port (`enP7s7`) — this is what cables to the NAS |
| **2× QSFP — ConnectX-7 NIC @ 200 Gbps** | High-speed networking for **Spark-to-Spark clustering** ("Spark stacking" → up to a 405B-param model across two Sparks). `mlx5` driver is loaded on the box. **QSFP, not RJ-45 — cannot connect to the NAS** (which is RJ-45 10 GbE) |
| **WiFi 7 + Bluetooth 5.4** | MediaTek 7925 (`wlP9s9`) |

### Live wiring (2026-07-01)

| Interface | What it is | State |
|---|---|---|
| `enP7s7` | the **10 GbE RJ-45** | UP 10 Gb/s — **cabled directly to the NAS** (`10.77.0.2/30`); waiting on the NAS side to get IP `10.77.0.1` |
| `enx6c6e…` | **USB gigabit dongle** (Realtek 8153, in the Anker dock) on a **USB 2.0 port** | carries LAN+internet (`192.168.10.205`) — capped ~40–125 MB/s |
| ConnectX-7 QSFP ×2 | 200 Gb/s cluster ports | uncabled (no 2nd Spark) |
| WG | WireGuard mesh | `10.1.0.5` |

- **No Thunderbolt** — the 4 USB-C ports are USB 3.2 Gen2×2 (20 Gb/s) + DP-alt, not TB. A TB cable into the DGX runs as USB.
- **10 GbE → NAS is the storage path** (already cabled): set the NAS 10 GbE port to `10.77.0.1/255.255.255.252`, remount NFS → ~1.25 GB/s. The QSFP ports don't help the NAS (wrong connector); they're for a second Spark.

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
