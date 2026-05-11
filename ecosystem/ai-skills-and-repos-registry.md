# AI Skills & Upstream Repos Registry

## Purpose

This registry tracks the AI skills, tools, CLIs, frameworks, and upstream repositories that support the You-Sir Juan private AI infrastructure platform.

The goal is to make every outside tool easy to understand:

- what it is
- what it does
- why it matters
- where it fits
- how it supports You-Sir Juan
- whether it should be integrated, forked, wrapped, studied, or white-labeled

---

# Core Principle

You-Sir Juan is not built from one model or one tool.

It is built from a coordinated ecosystem of:

- AI models
- coding agents
- memory systems
- design systems
- browser automation tools
- ingestion tools
- DevOps tools
- infrastructure tools
- evaluation tools
- productivity integrations

Each tool should serve a clear platform role.

---

# AI Coding & Developer Intelligence

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| Claude Code | AI coding agent | Lets the operator edit repos, generate files, refactor systems, and automate engineering workflows through terminal-based AI coding | approved |
| Continue.dev | IDE coding assistant | Connects local or cloud models into VS Code-style workflows for code completion, repo assistance, and developer productivity | approved |
| Aider | repo-aware coding CLI | Allows AI-assisted code edits directly inside Git repositories with commit-aware workflows | approved |
| OpenHands | autonomous engineering agent | Provides autonomous software development workflows, repo operations, testing, debugging, and code execution patterns | candidate |
| Roo Code | agentic IDE coding | Supports agent-style coding workflows inside editor environments | candidate |
| Devstral | coding model | Supports autonomous software engineering, refactoring, and coding workflows | candidate model |
| Qwen Coder | coding model | Strong coding model for local repo assistance, code generation, and engineering workflows | approved model |
| DeepSeek Coder | coding model | Strong code reasoning and repo understanding model | approved model |
| Codestral | coding model | Fast coding model for developer workflows and code assistance | candidate model |

---

# Local Model Runtime & Inference

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| Ollama | local model runtime | Runs open models locally for private inference, assistant workflows, coding, RAG, and experiments | integrated |
| vLLM | high-throughput inference server | Provides scalable local model serving for larger deployments and GPU-backed inference | candidate |
| Open WebUI | AI interface | Provides a local web interface for interacting with models, assistants, and private AI workflows | integrated |
| NVIDIA NIM | optimized model serving | Supports NVIDIA-native inference packaging for DGX Spark and CUDA infrastructure | candidate |
| TensorRT | NVIDIA inference optimization | Optimizes model execution on NVIDIA hardware such as DGX Spark | candidate |

---

# Recommended AI Models

| Model | Category | What It Does For You-Sir Juan | Best Hardware |
|---|---|---|---|
| DeepSeek R1 | reasoning | Heavy reasoning model for planning, analysis, and complex workflows | DGX Spark / high-memory local node |
| Qwen 3 | reasoning / multilingual | Strong general reasoning, multilingual support, and advanced local AI workflows | DGX Spark / Mac high-memory node |
| Llama 3.x | general reasoning | Balanced open model family for local AI assistants and reasoning | MacBook Pro / Mac mini / DGX Spark |
| Qwen Coder | coding | Local coding intelligence for repo work and automation | MacBook Pro / DGX Spark |
| DeepSeek Coder | coding | Code generation, debugging, and repo reasoning | MacBook Pro / DGX Spark |
| Gemma | lightweight assistant | Fast smaller assistant tasks and RAG support | Mac mini / MacBook Pro |
| Mistral | fast utility | Fast local response model for utility workflows | Mac mini / MacBook Pro |
| Phi | small edge model | Lightweight edge inference and small assistant tasks | Jetson Thor / Mac mini |
| Qwen-VL | multimodal | Vision-language reasoning for images, screenshots, and visual workflows | DGX Spark / Jetson Thor |
| LLaVA | multimodal | Image understanding and visual assistant workflows | Jetson Thor / DGX Spark |
| Florence | vision extraction | OCR-style image understanding and structured visual extraction | Jetson Thor / DGX Spark |
| Whisper | speech-to-text | Local transcription for voice workflows and meeting memory | Mac mini / Jetson Thor |
| Piper | text-to-speech | Local voice output for assistants | Jetson Thor / Mac mini |
| Kokoro | text-to-speech | Natural local TTS for assistant voice systems | Jetson Thor / Mac mini |

---

# RAG, Memory & Retrieval Systems

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| RAG Anything | multimodal RAG | Supports ingestion of PDFs, scanned records, images, and multimodal documents into memory systems | approved |
| Qdrant | vector database | Stores embeddings and powers semantic retrieval for assistant memory | integrated |
| LanceDB | local vector database | Optional local retrieval backend for embedded/private deployments | candidate |
| ChromaDB | vector database | Lightweight vector store for experiments and local memory prototypes | candidate |
| FAISS | vector search | Fast local vector search library for custom retrieval experiments | candidate |
| LlamaIndex | retrieval framework | Builds retrieval pipelines over documents, repos, and structured memory | candidate |
| LangChain | orchestration / RAG | Connects tools, models, retrievers, and workflows | candidate |
| SentenceTransformers | embeddings | Generates local embeddings for documents, chunks, and memory records | approved |
| bge-large | embedding model | Strong enterprise embedding model for semantic retrieval | approved model |
| nomic-embed | embedding model | Local-friendly embedding model for private retrieval systems | approved model |
| e5-large | embedding model | High-quality semantic embedding model | approved model |

---

# Browser Automation & Web Execution

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| Playwright CLI | browser automation | Lets agents control browsers, test dashboards, capture screenshots, and automate onboarding flows | approved |
| Browser-use | browser agent framework | Helps AI agents operate browsers and complete web tasks | candidate |
| Selenium | browser testing | Traditional browser automation/testing fallback | candidate |
| Firecrawl | web intelligence | Crawls websites, extracts structured content, and feeds web data into retrieval systems | approved |

---

# Design Intelligence & Frontend Quality

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| UI/UX Pro Max Skill | AI design skill | Gives AI stronger rules for layout, spacing, typography, UX flow, and polished interface generation | approved |
| AwesomeDesign.md | design critique | Provides frontend quality critique, polish rules, and design-improvement guidance | approved |
| 21st.dev | UI components | Provides modern hero sections, UI blocks, and component inspiration for premium pages | approved |
| Framer Motion | animation | Adds motion, transitions, and cinematic frontend behavior | approved |
| shadcn/ui | component foundation | Provides clean reusable UI primitives for dashboards and apps | approved |
| Tailwind CSS | styling | Utility-first styling and design token system | approved |
| Magic UI | animated components | Adds high-impact animated sections for landing pages and demos | candidate |
| Aceternity UI | premium UI effects | Provides advanced visual effects and interaction sections | candidate |
| Lucide Icons | icon system | Provides consistent modern iconography | approved |
| Three.js | 3D graphics | Enables 3D infrastructure diagrams, cinematic product visuals, and advanced marketing visuals | approved |
| React Three Fiber | React 3D layer | Brings Three.js into React/Next.js surfaces | approved |

---

# Website Generation & Marketing Automation

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| website-builder-setup | AI website workflow | Packages Claude Code, UI/UX skill workflows, component inspiration, and animations into a fast website-generation flow | candidate |
| AI Website Forge | internal feature | Converts PRDs and feature ledger items into landing pages, marketing pages, and product story pages | planned |
| Feature Ledger | product intelligence | Tracks every feature as a PRD, marketing asset, roadmap item, and selling point | active |
| Pain Journal | product discovery | Maps user pain to platform features and marketing language | active |

---

# Agent Frameworks & Multi-Agent Systems

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| OpenClaw | agent system | Provides autonomous agent patterns for operational workflows and assistant actions | approved |
| CrewAI | role-based agents | Coordinates specialist agents with roles and tasks | candidate |
| AutoGen | multi-agent orchestration | Supports multi-agent collaboration, debate, and task delegation | candidate |
| LangGraph | workflow graphs | Creates stateful multi-step agent graphs and workflow execution | candidate |
| Open Interpreter | local execution | Lets AI execute code and operate local tools under supervision | candidate |

---

# Evaluation, Testing & Trust Infrastructure

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| DeepEval | AI evaluation | Tests model outputs, hallucination risk, retrieval quality, and agent behavior | candidate |
| Promptfoo | prompt testing | Runs prompt regression tests and model comparisons | candidate |
| Playwright Tests | UI evaluation | Tests admin dashboards, marketing pages, onboarding flows, and browser workflows | approved |
| Recharts | analytics UI | Displays evaluation results, usage metrics, and dashboard analytics | approved |
| Sentry | observability | Tracks frontend/backend errors and production issues | approved |

---

# Productivity & Workspace Integrations

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| GWS | Google Workspace integration | Connects AI workflows to Gmail, Calendar, Docs, and Sheets | approved |
| Gmail integration | communications | Lets assistants summarize, draft, and organize communications when authorized | planned |
| Calendar integration | scheduling | Supports task scheduling, reminders, events, and operational coordination | planned |
| Docs integration | document memory | Adds document workflows into assistant memory and retrieval systems | planned |
| Sheets integration | structured data | Supports tabular workflows, trackers, ledgers, and operational reports | planned |

---

# DevOps, Git & Infrastructure Governance

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| Git | version control | Preserves operational memory, code history, assistant versions, and infrastructure changes | core |
| GitLab CE | private Git platform | Provides self-hosted repositories, CI/CD, runners, issues, artifacts, and governance | planned |
| GitHub | upstream sync | Hosts current repos and tracks upstream ecosystem work | active |
| Gitea | lightweight Git platform | Optional smaller self-hosted Git platform | candidate |
| Forgejo | community Git forge | Optional open-source Git hosting alternative | candidate |
| Git LFS | large file storage | Manages large model artifacts, datasets, and media files | candidate |
| GitLab Runners | CI/CD execution | Runs deployment, evaluation, ingestion, and build jobs | planned |
| GitLab Registry | container registry | Stores internal runtime containers and service images | planned |
| GitLab Packages | package registry | Stores internal packages, agents, and release artifacts | planned |

---

# Deployment & Infrastructure Platforms

| Tool / Repo | Purpose | What It Does For You-Sir Juan | Integration Status |
|---|---|---|---|
| Docker | containerization | Runs API, Postgres, Redis, Qdrant, Open WebUI, and workers | integrated |
| Docker Compose | local orchestration | Starts local/persistent platform services | integrated |
| PostgreSQL | database | Stores workspaces, namespaces, assistants, memory metadata, jobs, and audit logs | integrated schema |
| Redis | queue system | Coordinates ingestion, evals, browser jobs, assistants, and orchestration jobs | planned |
| nginx | reverse proxy | Routes public/private services and supports TLS termination | candidate |
| pm2 | process manager | Keeps Node/Next.js services running on VPS or local nodes | candidate |
| rsync | deployment sync | Supports simple VPS deployment patterns | candidate |
| GitHub Actions | CI/CD | Current automation path for repo checks and deployments | candidate |
| Coolify | self-hosted PaaS | Candidate deployment control panel | candidate |
| Dokploy | deployment platform | Candidate deployment manager | candidate |
| Terraform | infrastructure as code | Defines reproducible infrastructure | planned |
| Ansible | server automation | Automates server setup, hardening, and updates | planned |
| SOPS | secrets management | Encrypts environment files and deployment secrets | candidate |
| Vault | secrets management | Central secrets and policy engine | candidate |

---

# Hardware & Compute Infrastructure

| Hardware | Purpose | What It Does For You-Sir Juan |
|---|---|---|
| MacBook Pro M5 Max | main workstation | Local inference, coding, orchestration, design, creative work, repo operations |
| Mac mini M4 Max | persistent node | Always-on runtime, APIs, queues, Qdrant, Open WebUI, ingestion workers |
| NVIDIA DGX Spark | frontier inference node | CUDA workloads, fine-tuning, large-model serving, TensorRT, NVIDIA AI stack |
| NVIDIA Jetson Thor | edge AI node | Robotics, vision, voice, camera intelligence, multimodal edge inference |
| Flint 2 | infrastructure gateway | Home network routing, VPN, private connectivity |
| Slate AX | travel router | Secure travel networking and remote access |
| NAS / DAS / NVMe | storage | Model storage, backups, memory archives, embeddings, datasets |

---

# How These Tools Become One Platform

```text
Git + GitLab CE
    ↓
Versioned infrastructure and governance
    ↓
Runtime API + Docker + Postgres + Redis + Qdrant
    ↓
Model runtimes: Ollama / vLLM / NVIDIA stack
    ↓
Retrieval: RAG Anything + embeddings + vector DB
    ↓
Agents: Claude Code + Aider + OpenHands + OpenClaw
    ↓
Execution: Playwright CLI + Firecrawl + integrations
    ↓
Experience: Next.js + Tailwind + Framer Motion + design skills
    ↓
Feature system: PRDs + marketing sheets + pain journal
    ↓
You-Sir Juan private AI infrastructure platform
```

---

# What Each Category Adds

| Category | Adds |
|---|---|
| Coding Intelligence | ability to build, refactor, and operate software faster |
| Local Inference | private model execution |
| RAG / Memory | long-term contextual recall |
| Browser Automation | active web and UI execution |
| Design Intelligence | premium interfaces and stronger user trust |
| Agent Frameworks | autonomous workflows and task delegation |
| Evaluation | quality and trust scoring |
| Productivity Integrations | connection to real work systems |
| Git / DevOps | versioning, governance, CI/CD, and audit history |
| Hardware | compute power and workload separation |

---

# Next Required Registry Improvements

This registry should eventually add:

- source URLs
- licenses
- owner/maintainer
- fork status
- white-label status
- security review notes
- implementation priority
- install commands
- compatibility matrix
- feature IDs
- PRD links
- pain journal mappings

---

# Strategic Goal

The final system should not feel like scattered tools.

It should feel like:

> one coordinated private AI operating platform.

Every tool should have a job.
Every repo should have a role.
Every feature should have a PRD.
Every pain should map to a product improvement.
Every layer should make the system stronger.
