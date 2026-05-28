# Runtime Task Queue

## Purpose

The task queue coordinates:

- ingestion jobs
- assistant workflows
- evaluations
- browser automation
- embedding generation
- orchestration events

---

## Queue Categories

| Queue | Purpose |
|---|---|
| ingestion | PDFs, OCR, transcripts, web crawling |
| embeddings | vector generation |
| assistants | assistant execution tasks |
| evaluations | benchmark and validation jobs |
| browser | Playwright automation |
| orchestration | workflow coordination |
| audits | observability events |

---

## Long-Term Goal

Build full asynchronous execution infrastructure.
