# NVIDIA DGX Spark™ Frontier Inference Node

## Purpose

The NVIDIA DGX Spark™ is positioned inside the You-Sir Juan full cognitive operating system as:

> a full frontier inference and fine-tuning node.

It complements:

- Apple Silicon orchestration
- persistent runtime infrastructure
- edge multimodal AI
- full networking
- distributed inference systems

rather than replacing them.

---

# Full Hardware Mesh

| Hardware | Primary Role |
|---|---|
| MacBook Pro M5 Max • 128GB • 40-core GPU • 4TB SSD | orchestration workstation, coding, creative workflows |
| Mac mini M4 Max • 4TB SSD | persistent runtime, APIs, ingestion, queues, orchestration |
| NVIDIA DGX Spark™ | frontier inference, CUDA AI, fine-tuning, model serving |
| Jetson Thor | edge multimodal AI, robotics, voice, vision |
| Flint 2 | full gateway and infrastructure routing |
| Slate AX | secure travel networking |
| DAS / NAS / NVMe arrays | models, archives, embeddings, memory |

---

# Network access (fivemac — until further notice)

| Path | Alias / URL | Notes |
|------|-------------|-------|
| **Home LAN SSH** | `ssh nephew-spark-lan` → `192.168.10.205` | **Primary** while WG is down |
| **WireGuard SSH** | `ssh nephew-spark` → `10.1.0.5` | Remote mesh; down from fivemac 2026-07-02 |
| **Gitea git (LAN)** | `git@gitea-spark-lan:marvelousempire/<repo>.git` | Proxy to Spark `127.0.0.1:2424` |
| **Gitea HTTP** | `http://192.168.10.205:3300` | API probe; WG `:3300` down from fivemac |

Canonical runbook: [`ledger/LEDGER-0037-spark-lan-gitea-wiring/`](../ledger/LEDGER-0037-spark-lan-gitea-wiring/README.md).

---

# DGX Spark Role

DGX Spark is not treated as:

- a gaming computer
- a generic workstation
- a normal desktop machine

It is treated as:

> a compact full AI datacenter node.

---

# Primary Workloads

DGX Spark should specialize in:

- large-model inference
- CUDA-native AI workflows
- TensorRT acceleration
- LoRA / QLoRA fine-tuning
- autonomous coding workloads
- retrieval orchestration
- multi-agent inference
- model serving
- evaluation pipelines
- enterprise AI execution

---

# Strategic Difference

## Apple Silicon Nodes

Apple Silicon excels at:

- cinematic workflows
- UI engineering
- orchestration
- frontend development
- local coding workflows
- motion design
- editing and rendering
- full workstation ergonomics

---

## DGX Spark Node

DGX Spark excels at:

- CUDA-native inference
- TensorRT execution
- NVIDIA AI stack compatibility
- large-model serving
- enterprise inference
- GPU-heavy AI workflows
- distributed AI systems
- training acceleration

---

# Supported AI Categories

| Category | Example Models |
|---|---|
| Coding Intelligence | Qwen Coder, DeepSeek Coder, Devstral |
| Reasoning Models | DeepSeek R1, Llama 3.x, Qwen 3 |
| Multimodal Models | Qwen-VL, LLaVA |
| Retrieval Systems | bge-large, nomic-embed |
| Voice Systems | Whisper, Kokoro, Piper |
| Agentic Systems | OpenHands, OpenClaw, CrewAI |

---

# Full Compute Topology

```text
MacBook Pro M5 Max
    ↓
Creative Orchestration Layer

Mac mini M4 Max
    ↓
Persistent Runtime + APIs + Ingestion

NVIDIA DGX Spark
    ↓
Frontier Inference + Fine-Tuning + CUDA Workloads

Jetson Thor
    ↓
Edge Multimodal AI + Robotics + Voice + Vision
```

---

# Long-Term Goal

The long-term architecture evolves toward:

> a full distributed AI compute mesh.

Where:

- Apple Silicon handles orchestration and creative workflows
- DGX Spark handles frontier inference and training
- Jetson Thor handles edge multimodal execution
- Mac mini nodes handle persistent runtime infrastructure
- Tailscale and full networking connect the entire ecosystem

---

# Strategic Positioning

DGX Spark transforms the ecosystem from:

> a local AI workstation

into:

> full frontier AI infrastructure.

---

# House LAN operator access (fivemac mesh)

On the Family Office `192.168.10.0/24` mesh the DGX is tagged **nephew-spark** (`192.168.10.205`, Bonjour `nephew-spark.local`).

| Access | How |
|--------|-----|
| SSH | `ssh nephew-spark` (user `abrownsanta`) |
| SMB | `smb://abrownsanta@nephew-spark.local/Developer` |
| SFTP | `sftp://abrownsanta@nephew-spark.local` |

**mDNS hardening required** when Docker is heavy — see [LEDGER-0036](../ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/) and PAIN-0012. Mount by **hostname**, not raw IP, so Finder Network shows `nephew-spark.local` not `192.168.10.205`.
