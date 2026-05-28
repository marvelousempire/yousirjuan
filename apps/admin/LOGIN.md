# You-Sir Juan™ Admin Console Login Guide

This guide explains exactly how to open and access the local admin console.

---

# Current Login Reality

The admin console currently runs in:

```text
local development mode
```

At this stage:

- there is no production login page yet
- there are no cloud accounts yet
- there is no hosted server yet
- there is no external internet login yet

The current access method is:

```text
local trusted-machine access
```

through:

```text
http://localhost:3000
```

---

# Step-By-Step Access Instructions

## Step 1 — Install Required Software

Install these first:

| Software | Purpose |
|---|---|
| Docker Desktop | local infrastructure |
| Node.js 20+ | admin dashboard runtime |
| npm | package management |
| Git | repository management |

Recommended:

- VS Code
- Ollama

---

# Step 2 — Clone Repository

Open Terminal:

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
```

---

# Step 3 — Run Bootstrap

From the repo root:

```bash
bash bootstrap.sh
```

This prepares:

- machine profile
- folders
- lightweight runtime
- Docker services
- local AI infrastructure

On the MacBook Pro M1 2020 8GB profile, the bootstrap automatically selects lightweight mode.

---

# Step 4 — Start Admin Console

Open another terminal window:

```bash
cd apps/admin
npm install
npm run dev
```

Expected output:

```text
Local: http://localhost:3000
```

---

# Step 5 — Open Admin Console

Open browser:

```text
http://localhost:3000
```

You should now see:

- You-Sir Juan™ Admin Console
- system status cards
- hardware profile
- model runtime section
- vector memory section
- Skill Library section

---

# Step 6 — Verify Health API

Open:

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

# Step 7 — Verify Local AI Services

## Ollama

Open:

```text
http://localhost:11434
```

---

## Open WebUI

Open:

```text
http://localhost:8080
```

---

## Qdrant

Open:

```text
http://localhost:6333
```

---

# Current Security Model

At this stage, the system assumes:

- local machine access only
- trusted home-lab environment
- development mode
- non-public deployment

This is intentional while infrastructure matures.

---

# Future Login System

Planned future authentication:

- local-first auth
- operator accounts
- role-based permissions
- device trust
- audit logs
- emergency lockout
- session management
- encrypted secrets

Future login flow may eventually become:

```text
Trusted Device
    ↓
Operator Login
    ↓
Admin Console
```

---

# Common Problems

## Docker Not Running

Open Docker Desktop.

Then rerun:

```bash
bash bootstrap.sh
```

---

## Port 3000 In Use

Find process:

```bash
lsof -i :3000
```

---

## npm Install Errors

Reset:

```bash
rm -rf node_modules package-lock.json
npm install
```

---

## Blank Dashboard

Verify:

```bash
npm run dev
```

Then refresh:

```text
http://localhost:3000
```

---

# Current Reality

The system is currently:

- a locally runnable full AI runtime platform
- early-stage infrastructure
- partially operational
- development-oriented
- hardware-aware

It is not yet:

- a hosted SaaS platform
- a production cloud product
- a hyperscale AI provider

The focus remains:

- local inference
- orchestration
- retrieval
- memory
- skills
- operational continuity
- infrastructure ownership
