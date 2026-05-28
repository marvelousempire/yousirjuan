# Model Router

## Purpose

The model router determines which model handles a request.

---

## Routing Factors

| Factor | Purpose |
|---|---|
| namespace policy | local-only vs cloud-enabled |
| task type | coding, reasoning, retrieval |
| latency | fast vs deep inference |
| privacy level | full enforcement |
| cost | token and compute optimization |
| hardware availability | local GPU/edge selection |

---

## Example Routing

| Request | Preferred Model |
|---|---|
| coding | Qwen Coder |
| fast chat | Mistral |
| deep reasoning | Llama |
| evaluations | DeepSeek |
| retrieval synthesis | Gemma |

---

## Long-Term Goal

Create full multi-model orchestration infrastructure.
