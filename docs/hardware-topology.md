# Hardware Topology

# Purpose

This document explains how hardware roles are separated across the You-Sir Juan infrastructure.

One of the most common confusions is:

> what each device is actually responsible for.

This document clarifies:

- MacBook roles
- Mac mini roles
- Jetson Thor roles
- NAS roles
- DAS roles
- inference responsibilities
- storage responsibilities
- orchestration responsibilities

---

# Core Philosophy

Different hardware should specialize.

| Device | Primary Role |
|---|---|
| MacBook Pro M5 Max | creative workstation |
| Mac mini | always-on orchestration node |
| Jetson Thor | AI inference engine |
| NAS | long-term storage |
| DAS | ultra-fast active storage |

---

# MacBook Pro M5 Max

## Best At

- Blender
- Unreal Engine
- DaVinci Resolve
- Final Cut Pro
- Motion graphics
- software development
- orchestration
- AI-assisted creative workflows

## Responsibilities

- creative workstation
- coding environment
- AI-assisted editing
- orchestration control
- development workflows

## NOT Ideal For

- always-on server infrastructure
- heavy persistent inference workloads
- multi-user backend serving

---

# Mac mini

## Best At

- always-on services
- orchestration
- lightweight inference
- Open WebUI
- OpenClaw
- Tailscale coordination
- infrastructure automation

## Responsibilities

- infrastructure node
- assistant services
- background orchestration
- always-on automation

---

# Jetson Thor

## Best At

- AI inference
- embeddings
- vector operations
- robotics
- multimodal workloads
- autonomous systems
- edge AI

## Responsibilities

- heavy inference
- model serving
- vector search
- AI compute
- future robotics workloads

## NOT Ideal For

- Unreal Engine development
- DaVinci editing workflows
- Final Cut production
- creative workstation replacement

---

# NAS — Network Attached Storage

## Purpose

Long-term persistent storage.

## Stores

- documents
- uploads
- backups
- archives
- assistant memory snapshots
- logs
- media libraries

## Benefits

- redundancy
- backups
- network accessibility
- scalable storage

---

# DAS — Direct Attached Storage

## Purpose

Ultra-fast local active storage.

## Best Uses

- video editing
- active AI datasets
- Blender assets
- Unreal projects
- temporary high-speed workflows

## Clarification

DAS is NOT the AI brain.

It is:

> fast working storage.

---

# Example Home Topology

```text
Internet
    ↓
Flint 2
    ↓
Mac mini
    ↓
Jetson Thor
    ↓
NAS
```

Developer workstation:

```text
MacBook Pro M5 Max
       ↓
Tailscale
       ↓
Home Infrastructure
```

---

# Workload Separation

| Workload | Best Device |
|---|---|
| AI inference | Jetson Thor |
| Blender | MacBook Pro |
| Unreal Engine | MacBook Pro |
| DaVinci Resolve | MacBook Pro |
| Open WebUI hosting | Mac mini |
| Vector workloads | Jetson Thor |
| Long-term storage | NAS |
| Fast scratch storage | DAS |

---

# Long-Term Goal

The system should evolve toward:

- specialized infrastructure
- scalable inference
- persistent storage
- creative workstation separation
- full AI architecture

---

# iMac (Retina 4K, 21.5-inch, 2017) — Intel i5 64 GB

## Summary

An unofficial 64 GB RAM upgrade makes this 2017 Intel iMac a capable BYO tier runtime node despite its age. CPU-only Ollama inference limits it to smaller models, but the backend stack runs without constraint.

## Best At

- Always-on backend server (API, Postgres, Redis, Qdrant, nginx)
- Web interface hosting (Next.js)
- Light Ollama inference — llama3.2:3b for real-time voice, 8b models for async
- Docker services (x86_64 native)

## NOT Suitable For

- iOS 18 / visionOS 2 development (Ventura + Xcode 15 cap)
- Fast LLM inference (no Neural Engine, no CUDA)
- 70b model real-time voice turns (0.5–1 tok/sec is too slow)

## Recommended Ollama Model

`llama3.2:3b` — loads in ~2 GB, runs at 8–15 tok/sec on the i5, fast enough for 2–4 sec voice turn responses.

## Full Compatibility Doc

`docs/hardware/imac-2017-intel-i5.md`

