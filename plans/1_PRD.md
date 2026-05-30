**Product Requirements Document (PRD)**  
**Project Name:** Nephew – Private Enterprise Personal AI System  
**Version:** 1.0  
**Date:** May 29, 2026  
**Author:** Nephew (AI Assistant)

### 1. Objective
Build a high-performance, fully private, local AI system that functions as a highly intelligent, personalized executive assistant for a busy individual and his family. The system must outperform typical local AI setups in intelligence, organization, memory, and voice quality.

### 2. Vision
Create a best-in-class private AI called **Nephew** — an intelligent, culturally fluent, confident, and protective AI that deeply knows its owner’s financial, legal, family, and lifestyle matters. It must feel like a genius best friend rather than a generic chatbot.

### 3. Key Goals
- Full local/private operation (no cloud dependency)
- Domain-aware RAG with high retrieval quality
- Multiple specialized agents working under one unified system
- Natural, high-quality voice output
- Maximum use of available hardware (DGX Spark + MacBook Pro M5 Max)

### 4. Hardware Mapping
- **MacBook Pro M5 Max (128GB):** Open WebUI + Interface Layer
- **DGX Spark:** Main LLM, Agents, Retrieval, Embedding, Reranker
- **Server C & Server D (Temporary):** Qdrant + Redis storage
- **UGREEN DXP4800 Plus NAS:** Final long-term storage destination

### 5. Core Components & Requirements
- **LLM:** Support for both vLLM (preferred) and Ollama
- **Vector Database:** Qdrant with 4 separate collections (Financial, Legal, Family, General)
- **Embedding Model:** BAAI/bge-m3
- **Reranker:** Qwen3-Reranker-4B
- **Orchestrator:** LangGraph
- **Interface:** Open WebUI
- **Voice:** High-quality TTS (Fish Audio or Coqui TTS)
- **Memory:** Short-term in Redis, Long-term in Qdrant

### 6. Key Features
- Domain-specific knowledge collections with rich metadata
- Smart retrieval with metadata filtering
- Persistent personal memory and instruction following
- Multiple specialized agents (Accounting, Legal, Family, Lifestyle)
- Natural voice interaction
- Strong system persona ("Nephew")


### 7. Detailed Functional Requirements

**RAG & Knowledge Management:**
- Must support 4 separate Qdrant collections: `financial_collection`, `legal_collection`, `family_collection`, `general_collection`
- All documents must be processed with semantic chunking + recursive fallback
- Every chunk must contain rich metadata (domain, agent_target, doc_type, priority, source, chunk_id)
- Support ingestion from PDFs, Word docs, text files, and images (OCR)

**Agent System:**
- 4 dedicated agents: Accounting Agent, Legal Agent, Family Agent, Lifestyle Agent
- All agents must have access to the SmartRetriever
- Router logic in LangGraph to direct queries to correct agent or retrieval

**Core Persona:**
- The AI must always operate under the name **Nephew**
- Must follow the custom system prompt defining tone, personality, and behavior
- Must never hallucinate personal family information — only use retrieved context

**User Interface:**
- Primary interface via Open WebUI
- Must connect to LangGraph, not directly to the LLM
- Support for text and voice input/output

### 8. Non-Functional Requirements
- All services must run in Docker containers
- Must support easy migration from Server C/D to UGREEN NAS
- High performance on DGX Spark GPU
- All containers must have restart policies (`unless-stopped`)
- System must be stable with 10+ concurrent containers

### 9. Success Criteria
- When asked personal questions, Nephew must accurately reference stored personal documents
- Retrieval must return relevant results using metadata filtering
- Voice output must sound natural and human-like
- System must recover gracefully if any container crashes

### 10. Future Phases
- Phase 2: Advanced agent-to-agent collaboration
- Phase 3: Voice-first interface
- Phase 4: Automated document ingestion pipeline with monitoring

---

**This is our complete PRD.**

**System Architecture Document** next.