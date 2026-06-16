# RAG and knowledge bases

> **⚠️ Superseded for Family Office fleet operations.**  
> Canonical RAG: [`docs/setup/06-retrieval-and-memory.md`](setup/06-retrieval-and-memory.md) · [`docs/setup/16-knowledge-fabric-rag-quantization.md`](setup/16-knowledge-fabric-rag-quantization.md) · Nephew `docs/infrastructure/dgx-rag-and-fleet-state.md`.  
> This page describes **local Open WebUI + nomic-embed + chromadb** — valid for isolated dev only, **not** the DGX Brain A path (`bge-m3` → Qdrant → `bge-reranker-v2-m3` → tower-api `/api/v1/retrieve`).

---

# RAG and knowledge bases (legacy dev stack)

RAG = Retrieval-Augmented Generation. The model "reads" your documents at query time, pulling relevant chunks into the prompt. **Open WebUI has this built-in.** No extra setup.

## How it works

1. You upload documents (PDFs, docx, txt, markdown, URLs).
2. Open WebUI **chunks** them into ~500-token pieces.
3. Each chunk is **embedded** (turned into a vector) by a local embedding model (default: `nomic-embed-text` via Ollama).
4. Vectors stored in a local vector index (`chromadb` inside the container by default).
5. When you ask a question, Open WebUI:
   - Embeds your question
   - Finds the top-K most similar chunks
   - Stuffs them into the prompt as context
   - Sends to the LLM
6. LLM answers using your docs as context.

**Zero data leaves your machine** when Ollama and storage are local — but **fleet agents must use tower-api retrieve**, not this path.

## Fleet path (use this)

```bash
# On DGX or via WG from Mac
curl -s http://10.1.0.5:8088/api/v1/retrieve \
  -H 'Content-Type: application/json' \
  -d '{"query":"What does sovereign.md say?","top_k":5}'
```

Agents: MCP `nephew_corpus_retrieve` · eval gate: Nephew `evals/retrieval/`.

## The 5-minute setup (dev / Open WebUI workshop only)

### 1. Pull the embedding model
```bash
ollama pull nomic-embed-text   # 274 MB, very fast
```

### 2. In Open WebUI, configure embeddings (one-time)
**Admin Panel → Settings → Documents → Embedding Engine** → **Ollama** → model: `nomic-embed-text`.

### 3. Create a knowledge base
**Workspace → Knowledge → "Create a knowledge base"** → name it (e.g. *"Family Office — Q4 2026"*).

Upload files — drag-drop into the knowledge base, or paste URLs (Open WebUI fetches + parses them).

### 4. Attach knowledge to a custom model
**Workspace → Models → Create**:
- **Base model:** `llama3.1:8b` (or whatever you prefer)
- **System prompt:** *"You are the Yousirjuan family office assistant. Cite sources when referencing the knowledge base. Never speculate about financials without citing."*
- **Knowledge:** select the knowledge base you just created
- Save.

### 5. Use it
Pick the new model from the chat dropdown. Ask questions about the docs you uploaded. The model pulls relevant chunks and answers with them.

## Tips

- **More docs = better answers**, but also slower retrieval. Aim for one knowledge base per topic (e.g. "Tax docs", "Legal", "Investments") rather than one giant one.
- **Cite sources**: include "cite the source document" in the system prompt. Open WebUI displays which chunks were retrieved with each answer.
- **Update by re-uploading**: replace files in the knowledge base when docs change. Open WebUI re-embeds automatically.
- **Try `llava:13b` for vision** if your docs are scanned PDFs / image-heavy — it can read images directly. Combined with RAG it's powerful.
