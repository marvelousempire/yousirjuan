# Model-to-Hardware Mapping

## Purpose

This document explains which AI models and workloads belong on which hardware inside the You-Sir Juan infrastructure stack.

The goal is to:

- prevent overload
- optimize inference
- separate workloads
- guide purchasing
- simplify scaling
- improve orchestration planning

---

# Core Hardware Nodes

| Node | Primary Role |
|---|---|
| MacBook Pro M5 Max | orchestration workstation |
| Mac mini M4 Pro | persistent runtime server |
| NVIDIA DGX Spark | frontier inference and CUDA workloads |
| NVIDIA Jetson Thor | edge AI and multimodal robotics |

---

# Coding & Reasoning Models

| Model | Recommended Hardware | Why |
|---|---|---|
| Qwen Coder | MacBook Pro / DGX Spark | strong coding workflows |
| DeepSeek Coder | MacBook Pro / DGX Spark | repo reasoning and automation |
| Devstral | DGX Spark | larger coding workloads |
| Codestral | MacBook Pro | fast local coding |
| DeepSeek R1 | DGX Spark | advanced reasoning and long context |
| Qwen 3 | DGX Spark / MacBook Pro | multilingual reasoning and orchestration |
| Llama 3.x | MacBook Pro / Mac mini | balanced local assistants |
| Gemma | Mac mini | lightweight RAG workflows |
| Mistral | Mac mini | fast low-latency assistants |
| Phi | Jetson Thor / Mac mini | small edge inference |

---

# Voice & Audio Models

| Model / System | Recommended Hardware | Why |
|---|---|---|
| Whisper | Mac mini / Jetson Thor | transcription and audio ingestion |
| Piper | Mac mini | lightweight local TTS |
| Kokoro | MacBook Pro / Mac mini | higher-quality local voice generation |
| ElevenLabs workflows | MacBook Pro | cloud-assisted narration and demos |
| AudioCraft | DGX Spark | audio generation experiments |

---

# Vision & Multimodal Models

| Model | Recommended Hardware | Why |
|---|---|---|
| Qwen-VL | DGX Spark / Jetson Thor | image and multimodal reasoning |
| LLaVA | Jetson Thor / DGX Spark | image understanding |
| Florence | Jetson Thor | OCR and visual extraction |
| LivePortrait | DGX Spark | avatar and talking portrait workflows |
| FaceFusion | DGX Spark | video and face-processing pipelines |

---

# Media Generation Systems

| System | Recommended Hardware | Why |
|---|---|---|
| Higgsfield | DGX Spark | cinematic generation workloads |
| Seedance | DGX Spark | AI motion and video workloads |
| ComfyUI | DGX Spark / MacBook Pro | modular generation orchestration |
| Flux | DGX Spark | premium image generation |
| AnimateDiff | DGX Spark | motion generation |
| Deforum | DGX Spark | cinematic diffusion rendering |

---

# Infrastructure Services

| Service | Recommended Hardware | Why |
|---|---|---|
| Open WebUI | Mac mini | persistent local UI |
| Ollama | Mac mini / MacBook Pro | local model serving |
| Qdrant | Mac mini | vector memory runtime |
| PostgreSQL | Mac mini | persistent structured storage |
| Redis | Mac mini | queue and orchestration jobs |
| GitLab CE | Mac mini / VPS | CI/CD and operational governance |
| Docker | all nodes | runtime isolation |
| WireGuard | Flint 2 / Slate AX | secure networking |

---

# Strategic Principle

Not every node should do everything.

The system scales better when:

- orchestration
- inference
- storage
- media generation
- edge AI
- voice
- retrieval

are separated into specialized workloads.

---

# Long-Term Goal

The infrastructure should evolve toward:

> a coordinated distributed AI compute mesh.
