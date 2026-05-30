**System Architecture Document**

**Project Name:** Nephew – Private Enterprise Personal AI System  
**Document Type:** System Architecture  
**Version:** 1.0

### 1. High-Level Architecture Overview

The system follows a clean layered architecture:

- **Interface Layer** → MacBook Pro M5 Max
- **Orchestration Layer** → MacBook Pro M5 Max (LangGraph)
- **Agent Layer** → DGX Spark
- **Retrieval Layer** → DGX Spark
- **Model Layer** → DGX Spark
- **Knowledge Layer** → Server C/D (moving to UGREEN NAS later)

### 2. Hardware Allocation

| Hardware                    | Role                                      | Key Services                              |
|----------------------------|-------------------------------------------|-------------------------------------------|
| MacBook Pro M5 Max (128GB) | Interface + Orchestration                 | Open WebUI, LangGraph                     |
| DGX Spark                  | Heavy AI Workload                         | Main LLM, Agents, Embedding, Reranker     |
| Server C & Server D        | Temporary Storage                         | Qdrant, Redis                             |
| UGREEN DXP4800 Plus NAS    | Permanent Storage (Future)                | Qdrant (final location)                   |
| 21.5-inch Mac (64GB)       | Support                                   | Ingestion Pipeline                        |

### 3. Container Architecture

**Core Services:**
- qdrant
- redis
- main-llm (vLLM preferred)
- embedding-service
- reranker-service
- langgraph-orchestrator
- open-webui

**Agent Services:**
- accounting-agent
- legal-agent
- family-agent
- lifestyle-agent

**Support Services:**
- ingestion-pipeline
- tts-service

### 4. Data Flow
User → Open WebUI → LangGraph → Router → Agent or SmartRetriever → Qdrant → Context returned to LLM

**Container & Services Specification** document next.