**Data & RAG Strategy Document**

**Project Name:** Nephew – Private Enterprise Personal AI System  
**Document Type:** Data & RAG Strategy  
**Version:** 1.0

### 1. RAG Philosophy
We are not building a generic RAG. We are building a **domain-aware, metadata-rich, high-precision** personal knowledge system.

### 2. Collection Strategy

The system uses **4 separate Qdrant collections**:

- **financial_collection** – Banking, investments, taxes, accounting documents
- **legal_collection** – Contracts, legal notices, court documents, attorney correspondence
- **family_collection** – Medical records, school documents, family instructions, nanny/chef info
- **general_collection** – All other personal documents and rules

### 3. Chunking Strategy
- Primary method: **SemanticChunker** (using BAAI/bge-m3 embeddings)
- Fallback method: RecursiveCharacterTextSplitter (700 token chunks, 80 token overlap)
- Goal: Create meaningful, contextually coherent chunks

### 4. Metadata Strategy
Every document chunk must include these metadata fields:
- `domain` (financial, legal, family, general)
- `agent_target` (accounting, legal, family, lifestyle)
- `doc_type` (instruction, rule, memory, reference, note)
- `priority` (high, medium, low)
- `source` (filename)
- `chunk_id` (unique identifier)

### 5. Ingestion Folder Structure
All raw documents must be organized as follows:
```
data/raw-docs/
├── financial/
├── legal/
├── family/
└── general/
```

### 6. Retrieval Strategy
- Use metadata filtering when domain is known
- Use SmartRetriever class for intelligent routing
- Always apply reranking on final results

---

**Agent Design Document** next.