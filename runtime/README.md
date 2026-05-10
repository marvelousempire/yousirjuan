# Runtime Layer

## Purpose

The runtime layer turns the platform from documentation into execution.

It coordinates:

- assistants
- tasks
- workflows
- namespaces
- model routing
- retrieval permissions
- evaluations
- audit events

---

## Runtime Components

| Component | Purpose |
|---|---|
| Assistant Runtime Manager | starts, stops, versions, and routes assistant sessions |
| Namespace Resolver | decides which memory each assistant may access |
| Model Router | routes tasks to local, edge, or allowed cloud models |
| Workflow Executor | runs repeatable task chains |
| Agent Lifecycle Manager | manages autonomous agents and approval states |
| Task Queue | schedules ingestion, evals, and automation jobs |
| Audit Emitter | writes observable runtime events |

---

## Execution Flow

```text
User Request
   ↓
Assistant Runtime Manager
   ↓
Namespace Resolver
   ↓
Model Router
   ↓
Retrieval / Tools / Workflow
   ↓
Evaluation Guardrails
   ↓
Response + Audit Event
```

---

## Runtime Rule

No assistant may retrieve memory, call a tool, route to a model, or execute a workflow without passing policy checks.
