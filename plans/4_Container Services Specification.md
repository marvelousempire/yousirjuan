**Container & Services Specification Document**

**Project Name:** Nephew – Private Enterprise Personal AI System  
**Document Type:** Container & Services Specification  
**Version:** 1.0

### 1. Full Container List

**Infrastructure Services:**
- **qdrant** – Vector database (runs on Server C/D → later NAS)
- **redis** – Short-term memory and LangGraph state
- **main-llm** – Primary reasoning model (vLLM recommended)
- **embedding-service** – Text embeddings (BAAI/bge-m3)
- **reranker-service** – Result reranking (Qwen3-Reranker-4B)
- **langgraph-orchestrator** – Central brain and router
- **open-webui** – Main user interface

**Agent Services:**
- **accounting-agent**
- **legal-agent**
- **family-agent**
- **lifestyle-agent**

**Supporting Services:**
- **ingestion-pipeline** – Document processing and loading
- **tts-service** – Text-to-Speech (voice output)

### 2. Storage Strategy
- All persistent data (Qdrant collections) stored on Server C or D for now
- Redis data also stored on Server C/D
- When UGREEN NAS arrives, only the Qdrant `/storage` folder needs to be moved

### 3. Network
All containers communicate through a shared Docker network called `ai-network`

### 4. Volume Mounts
- Qdrant data: `~/ai-os/data/qdrant`
- Redis data: `~/ai-os/data/redis`
- Raw documents: `~/ai-os/data/raw-docs`
- Open WebUI data: `~/ai-os/data/open-webui`

---

**Data & RAG Strategy Document** next.