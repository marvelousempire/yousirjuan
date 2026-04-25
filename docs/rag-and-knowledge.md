# RAG and knowledge bases

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

**Zero data leaves your machine.** Everything (embedding, storage, retrieval, generation) is local.

## The 5-minute setup

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
- **Larger context windows help**: a 128k-context model can fit ~50 chunks; an 8k-context model only fits ~6. Larger = better recall, slower.

## Per-user vs shared knowledge

- **Per-user knowledge**: each family member uploads their own private docs (medical, personal). Stays on their account only.
- **Shared knowledge**: admin (you) uploads to a public model. All users can chat with it. Use case: "Family Office Assistant" with shared policies.

See [`multi-user.md`](multi-user.md) for the sharing mechanism.

## Security considerations

- Documents are stored in the Open WebUI Docker volume (`/var/lib/docker/volumes/open-webui/_data/uploads/`). Volume is on your VPS disk.
- Embeddings are stored in `chromadb` in the same volume.
- **At-rest encryption is your job** — encrypt the host disk (LUKS) if the VPS provider doesn't already.
- If you back up the volume (`tools/backup.sh`), the backup contains everything. Encrypt your backup tarball before storing off-site.

## RAG vs fine-tuning — when to use which

| | RAG (this doc) | Fine-tuning |
|---|---|---|
| **What it changes** | What the model has access to (read-only context) | The model's weights themselves (permanent learning) |
| **Setup time** | 5 min | Hours-to-days, GPU recommended |
| **Updates** | Re-upload files; re-embed; instant | Re-train; new GGUF; re-import |
| **Best for** | Living documents, large corpora, multiple users with separate docs | Stable knowledge baked into a model's "personality" |
| **Cost** | $0 if local | $0 if local on your GPU; $$$ if cloud |
| **Privacy** | Fully local | Fully local |

**For family-office work (financials, contracts, policies that change), RAG is the right tool every time.**
