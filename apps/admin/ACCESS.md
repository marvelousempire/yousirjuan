# Access Instructions

This document explains how to access the Ready Play Administrative Dashboard and core local AI services.

---

# Local Development Access

## 1. Start the platform

From the repository root:

```bash
bash bootstrap.sh
```

This prepares the local runtime environment and starts the lightweight full AI stack.

---

# Core Local URLs

## Ready Play Administrative Dashboard

```text
http://localhost:3000
```

Purpose:

- main operator dashboard
- system health
- local model status
- orchestration visibility
- skill library access
- infrastructure controls

---

## Ollama API

```text
http://localhost:11434
```

Purpose:

- local model inference
- model management
- local AI requests

Example:

```bash
curl http://localhost:11434/api/tags
```

---

## Open WebUI

```text
http://localhost:8080
```

Purpose:

- local ChatGPT-style interface
- local model chat
- RAG interaction
- assistant testing

---

## Qdrant Vector Database

```text
http://localhost:6333
```

Purpose:

- vector memory
- embeddings
- retrieval infrastructure
- semantic search

---

# Admin Dashboard Development

## Install dependencies

```bash
cd apps/admin
npm install
```

---

## Run development server

```bash
npm run dev
```

---

## Open dashboard

```text
http://localhost:3000
```

---

# Lightweight M1 8GB Profile

The bootstrap system automatically detects lightweight hardware profiles.

For the MacBook Pro M1 2020 8GB configuration:

- lightweight models are preferred
- only core services are started
- memory-heavy orchestration is disabled by default
- larger infrastructure activates automatically on stronger hardware later

Recommended lightweight models:

- tinyllama
- phi3-mini
- qwen2.5:0.5b
- qwen2.5:1.5b

---

# Future Workstation Upgrade Path

When stronger hardware is detected:

- additional services auto-enable
- larger models become available
- orchestration expands
- vector workloads increase
- evaluation systems scale up

without requiring a repo redesign.

---

# Important Reality Note

The repository is currently:

- an early-stage full AI runtime platform
- partially implemented infrastructure
- active development architecture
- evolving orchestration system

It is not yet:

- a production enterprise platform
- hyperscale infrastructure
- a replacement for frontier cloud providers

The focus is:

- private AI infrastructure
- local-first orchestration
- full deployment
- retrieval systems
- coding workflows
- operational continuity
