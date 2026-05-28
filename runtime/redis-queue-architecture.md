# Redis Queue Architecture

## Purpose

Redis queues coordinate asynchronous Family Office runtime execution.

---

## Planned Queues

| Queue | Purpose |
|---|---|
| ingestion | document ingestion jobs |
| embeddings | vector generation |
| orchestration | workflow coordination |
| assistants | assistant execution |
| browser | Playwright automation |
| evals | benchmark validation |
| billing | usage metering |
| audits | observability events |

---

## Planned Flow

```text
API Request
   ↓
Redis Queue
   ↓
Worker
   ↓
Runtime Execution
   ↓
Audit Event
   ↓
Persistent Storage
```

---

## Long-Term Goal

Build resilient full asynchronous infrastructure.
