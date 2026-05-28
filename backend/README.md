# Backend Service

## Purpose

The backend service is the persistent operational core for You-Sir Juan.

It will manage:

- users
- workspaces
- assistants
- namespaces
- memory records
- feature ledger records
- pain journal entries
- billing usage
- audit logs
- orchestration jobs
- ingestion jobs
- evaluation runs

---

## Planned Stack

| Layer | Technology |
|---|---|
| API | Node.js / Express |
| Database | PostgreSQL |
| Queue | Redis |
| Vector DB | Qdrant |
| Runtime | Docker |
| Auth | JWT / session cookies |
| Admin | Next.js |

---

## Long-Term Goal

Turn the repo from documentation plus scripts into a persistent full AI operating platform.
