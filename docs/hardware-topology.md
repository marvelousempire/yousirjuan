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
- sovereign AI architecture
