# Ready Play Administrative Dashboard Usage Guide

This guide explains how to install, run, access, and operate the Ready Play Administrative Dashboard locally.

---

# What Is This?

The Ready Play Administrative Dashboard is the operator control center for You-Sir Juan™.

It is intended to provide visibility into:

- local AI infrastructure
- models
- vector memory
- retrieval systems
- orchestration
- device permissions
- skills
- workflows
- system health
- logs

---

# Current Runtime State

The dashboard is currently:

- early-stage
- locally runnable
- development-oriented
- infrastructure-focused
- partially implemented

The dashboard is not yet:

- production enterprise software
- fully authenticated
- feature complete
- hardened for internet exposure

Use locally on trusted networks only.

---

# Requirements

## Minimum Recommended Machine

Supported lightweight target:

- MacBook Pro M1 2020
- 8GB RAM
- Apple Silicon

Recommended stronger systems:

- Mac mini M4 Pro
- MacBook Pro M5 Max

---

# Required Software

Install:

- Docker Desktop
- Node.js 20+
- npm
- Git

Optional:

- Ollama desktop
- VS Code
- Continue.dev

---

# First-Time Setup

## 1. Clone repository

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
```

---

## 2. Run bootstrap

```bash
bash bootstrap.sh
```

The bootstrap system:

- detects machine profile
- prepares folders
- configures lightweight mode on M1 8GB
- starts local infrastructure services
- prepares future scaling paths

---

## 3. Start admin dashboard

```bash
cd apps/admin
npm install
npm run dev
```

---

# Access URLs

## Admin Dashboard

```text
http://localhost:3000
```

---

## Health API

```text
http://localhost:3000/api/health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

## Ollama

```text
http://localhost:11434
```

---

## Open WebUI

```text
http://localhost:8080
```

---

## Qdrant

```text
http://localhost:6333
```

---

# Current Dashboard Sections

## Overview

Displays:

- runtime profile
- infrastructure state
- local service visibility
- hardware profile

---

## Models

Planned for:

- local model registry
- loaded models
- model memory usage
- model pull status
- model health

---

## Services

Planned for:

- Ollama status
- Open WebUI status
- Qdrant status
- Redis status
- PostgreSQL status
- orchestration runtime status

---

## Skill Library

Planned for:

- installed skills
- skill metadata
- skill categories
- skill execution
- bridge skills

---

## Devices

Planned for:

- Apple device permissions
- sensor event visibility
- device signal broker
- local consent controls

---

## Evals

Planned for:

- coding evaluations
- retrieval evaluations
- hallucination checks
- workflow scoring

---

# Lightweight M1 8GB Guidance

The lightweight profile intentionally avoids:

- giant models
- multi-agent swarms
- heavy orchestration
- memory-heavy embedding jobs

Recommended models:

- tinyllama
- phi3-mini
- qwen2.5:0.5b
- qwen2.5:1.5b

Avoid on 8GB:

- 32B models
- 70B models
- large vector ingestion jobs

---

# Pull First Model

Example:

```bash
docker exec -it yousirjuan-ollama ollama pull tinyllama
```

---

# Troubleshooting

## Port 3000 already in use

Stop conflicting app:

```bash
lsof -i :3000
```

---

## Docker not running

Open Docker Desktop and retry:

```bash
bash bootstrap.sh
```

---

## Node modules corrupted

Reset:

```bash
rm -rf node_modules package-lock.json
npm install
```

---

## Dashboard does not load

Verify:

```bash
npm run dev
```

and open:

```text
http://localhost:3000
```

---

# Current Reality

The platform is currently:

- sovereign AI infrastructure in active development
- local-first runtime architecture
- partially operational
- infrastructure-focused
- evolving iteratively

The focus is:

- local inference
- orchestration
- retrieval
- coding workflows
- operational continuity
- infrastructure ownership

rather than AGI claims or frontier-model equivalence.
