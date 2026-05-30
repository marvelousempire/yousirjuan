**BUILD PLAN FOR Nephew – PRIVATE ENTERPRISE PERSONAL AI SYSTEM**

**Version:** 1.0  
**Date:** May 29, 2026  
**Purpose:** Complete, step-by-step execution plan to build the full system without missing critical pieces.

---

### Phase 1: Foundation & Infrastructure Setup

**Goal:** Get the core services running cleanly on the DGX Spark.

**Step 1.1** – Prepare the DGX Spark
- Update system and install Docker + Docker Compose
- Install NVIDIA Container Toolkit
- Create project structure: `~/ai-os/{data/qdrant, data/redis, data/raw-docs, config, ingestion, langgraph, retrieval, agents, logs}`
- Create Docker network: `ai-network`

**Step 1.2** – Deploy Core Services
- Create and run `docker-compose.yml` with:
  - Qdrant (store on Server C or D)
  - Redis (with persistence and password)
- Verify both containers are healthy

**Step 1.3** – Deploy Main LLM (Choose One)
- **Recommended:** Deploy vLLM with Qwen3-72B or DeepSeek-V4
- **Alternative:** Deploy Ollama + pull strong model
- Test that the model responds correctly via API

---

### Phase 2: Knowledge & RAG System

**Goal:** Build a high-quality, domain-aware RAG system.

**Step 2.1** – Organize Raw Documents
- Create folder structure inside `data/raw-docs/`:
  - `financial/`
  - `legal/`
  - `family/`
  - `general/`
- Move all existing instruction files, rules, skills, and documents into the correct folders

**Step 2.2** – Build Ingestion Pipeline
- Create `ingest.py` using:
  - SemanticChunker + Recursive fallback
  - Rich metadata tagging on every chunk
  - Separate collections in Qdrant
- Run ingestion and verify chunks are stored correctly in 4 collections

**Step 2.3** – Deploy Embedding + Reranker Services
- Deploy `embedding-service` (BAAI/bge-m3)
- Deploy `reranker-service` (Qwen3-Reranker-4B)
- Test both services are responding

---

### Phase 3: Intelligence Layer (Agents + Orchestration)

**Goal:** Build the brain and specialized agents.

**Step 3.1** – Create SmartRetriever
- Build `retrieval/retriever.py` with domain-aware search + metadata filtering
- Create helper functions so agents can easily call retrieval

**Step 3.2** – Deploy LangGraph Orchestrator
- Create LangGraph service
- Connect it to Main LLM, Qdrant, Redis, and SmartRetriever
- Add basic router logic

**Step 3.3** – Build the Four Agents
- Create separate containers/services for:
  - Accounting Agent
  - Legal Agent
  - Family Agent
  - Lifestyle Agent
- Each agent must be able to call the SmartRetriever

**Step 3.4** – Define System Persona
- Create `system_prompt.txt` with strong "Nephew" persona
- Load it into LangGraph so every response follows the correct tone and behavior

---

### Phase 4: Interface & Experience

**Goal:** Make the system usable and polished.

**Step 4.1** – Deploy Open WebUI
- Connect it to LangGraph (not directly to the LLM)
- Test chat interface works end-to-end

**Step 4.2** – Add Voice (TTS)
- Deploy TTS service (Fish Audio or Coqui TTS)
- Test voice output quality

**Step 4.3** – Add Monitoring
- Add basic monitoring for container health, GPU usage, and memory
- Set proper restart policies on all containers

---

### Phase 5: Testing, Validation & Hardening

**Goal:** Make sure the system actually works as intended.

**Step 5.1** – Personal Knowledge Test
- Ask very specific questions about your life, family, finances, and rules
- Verify Nephew pulls accurate information from the correct collections

**Step 5.2** – Agent Routing Test
- Test that the system correctly routes questions to the right agent

**Step 5.3** – Migration Plan
- Document exact steps to move Qdrant data from Server C/D to the UGREEN NAS when it arrives

**Step 5.4** – Documentation Handoff
- Finalize all documents (PRD, Architecture, Container Spec, RAG Strategy, Agent Design, Build Plan)
- Create a clean handoff package so other agents or developers can continue building

---

### Execution Order Recommendation

Do **not** skip phases. Build in this order:

1. Phase 1 (Foundation)
2. Phase 2 (RAG)
3. Phase 3 (Agents + Orchestration)
4. Phase 4 (Interface)
5. Phase 5 (Testing)

Would you like me to now expand any specific phase with more detailed commands and file contents? Or would you like the **Agent Design Document** next?