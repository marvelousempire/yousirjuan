# You-Sir Juan™ Admin Console

The You-Sir Juan™ Admin Console is the operator-facing control surface for the full AI infrastructure platform.

It is designed to manage:

- local AI services
- model status
- RAG ingestion
- memory systems
- Skill Library operations
- automation workflows
- device signal permissions
- evaluation results
- logs and system health
- orchestration activity

---

## Current Access Status

The admin console currently runs in local development mode.

Current behavior:

- no production login screen yet
- no hosted cloud account yet
- no external public access yet
- local access only through `localhost`

Current access URL:

```text
http://localhost:3000
```

Future production access will add:

- local-first authentication
- operator accounts
- role-based access
- trusted-device login
- emergency lockout controls
- audit logging

---

## Purpose

The admin console is not a marketing page.

It is the administrative cockpit for the You-Sir Juan™ full AI infrastructure platform.

It should make the system:

- visible
- controllable
- measurable
- safe
- explainable
- locally owned

---

## Initial Tech Stack

| Layer | Stack |
|---|---|
| Framework | Next.js App Router |
| Language | TypeScript |
| Styling | Tailwind CSS |
| UI Components | shadcn/ui |
| Motion | Framer Motion |
| State | Zustand |
| Server State | TanStack Query |
| Tables | TanStack Table |
| Charts | Recharts / Tremor-compatible patterns |
| Graphs | React Flow |
| Forms | React Hook Form + Zod |
| Auth | Local-first auth adapter planned |
| API | REST first, tRPC optional later |
| Live Updates | WebSocket / Server-Sent Events |
| Terminal UI | xterm.js |
| Icons | lucide-react |
| Testing | Vitest + Playwright |

---

## Console Modules

| Module | Purpose |
|---|---|
| Overview | System summary and health |
| Models | Local model registry and runtime status |
| Services | Ollama, Open WebUI, Qdrant, Redis, Postgres |
| Memory | Long-term memory and retrieval visibility |
| RAG Ingestion | Document, repo, PDF, and transcript ingestion |
| Skills | Skill Library browsing and invocation state |
| Agents | Local agent sessions and activity |
| Workflows | Automation builder and workflow runs |
| Devices | Apple device signal broker and permissions |
| Evals | Model and workflow evaluation results |
| Logs | Runtime logs and audit events |
| Settings | Profiles, security, API keys, local policies |

---

## Folder Structure

```text
apps/admin/
  README.md
  ACCESS.md
  USAGE.md
  LOGIN.md
  package.json
  next.config.ts
  tsconfig.json
  postcss.config.mjs
  tailwind.config.ts
  src/
    app/
    components/
    config/
    features/
    hooks/
    lib/
    server/
    styles/
    types/
```

---

## Development Goal

The first working version should show:

- detected hardware profile
- local service status
- model registry
- system health cards
- logs panel
- Skill Library index
- placeholder device permissions panel

---

## Run Target

Run locally with:

```bash
cd apps/admin
npm install
npm run dev
```

Then open:

```text
http://localhost:3000
```

The broader platform can be prepared with:

```bash
bash bootstrap.sh
```

---

## White-Label Rule

This admin console belongs to You-Sir Juan™.

Avoid legacy names such as:

- Ready Play Administrative Dashboard
- Red-E Play dashboard
- generic admin template

Use:

- You-Sir Juan™ Admin Console
- You-Sir Juan™ full AI infrastructure
- Skill Library
- Full Cognitive Forge™

---

## Design Standard

The admin console should feel like:

- command center
- private AI cockpit
- family-office control board
- infrastructure admin panel
- calm, precise, high-trust system

Avoid:

- toy chatbot UI
- vague AGI language
- hidden controls
- unclear sensor permissions
- unsafe destructive actions
