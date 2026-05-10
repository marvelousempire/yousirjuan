# Ready Play Administrative Dashboard

The Ready Play Administrative Dashboard is the operator-facing control surface for You-Sir Juan™.

It is designed to manage:

- local AI services
- model status
- RAG ingestion
- memory systems
- skill library operations
- automation workflows
- device signal permissions
- evaluation results
- logs and system health
- orchestration activity

---

## Purpose

The dashboard is not a marketing page.

It is the administrative cockpit for the sovereign AI infrastructure platform.

It should make the system visible, controllable, measurable, and safe.

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
| Auth | Auth.js or local-first auth adapter |
| API | REST first, tRPC optional later |
| Live Updates | WebSocket / Server-Sent Events |
| Terminal UI | xterm.js |
| Icons | lucide-react |
| Testing | Vitest + Playwright |

---

## Dashboard Modules

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
- skill library index
- placeholder device permissions panel

---

## Run Target

The dashboard should eventually run through:

```bash
cd apps/admin
npm install
npm run dev
```

and later be launched by:

```bash
bash bootstrap.sh
```

---

## Design Standard

The dashboard should feel like:

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
