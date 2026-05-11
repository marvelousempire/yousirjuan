# AI Skills Catalog

## Purpose

This folder explains the AI skills, agent skills, design skills, automation skills, and workflow skills used inside the You-Sir Juan platform.

The goal is to make the skill layer easy to understand for:

- developers
- operators
- customers
- implementation partners
- future contributors

Each skill should explain:

- what it does
- why it matters
- where it fits
- how You-Sir Juan uses it
- whether it is active, planned, or candidate

---

# Skill Categories

| Category | Purpose |
|---|---|
| Coding Skills | build, refactor, test, and maintain code |
| Design Skills | improve UI, layout, accessibility, and visual polish |
| Retrieval Skills | ingest and search documents, images, and memory |
| Browser Skills | automate websites, tests, screenshots, and onboarding flows |
| Media Skills | generate video, voice, images, and cinematic assets |
| Evaluation Skills | test model quality, hallucinations, workflows, and output safety |
| Productivity Skills | connect AI to email, calendar, docs, sheets, and operations |
| Infrastructure Skills | deploy, monitor, version, and operate the platform |

---

# Current AI Skills

| Skill / System | Category | What It Does | You-Sir Juan Use |
|---|---|---|---|
| Claude Code | Coding | terminal-based AI coding and repo editing | builds and modifies platform files, services, docs, and workflows |
| Continue.dev | Coding | IDE AI coding assistant | connects local/cloud models to developer workflows |
| Aider | Coding | Git-aware coding assistant | makes repo changes with commit-friendly workflows |
| OpenHands | Coding / Agents | autonomous engineering agent | future autonomous build, test, and repair workflows |
| Roo Code | Coding / Agents | editor-based agent workflow | future IDE-native agentic coding layer |
| UI/UX Pro Max | Design | design reasoning, layout, UX flow, and polish | improves admin, marketing, and assistant interfaces |
| AwesomeDesign.md | Design | frontend critique and design quality rules | reviews and improves AI-generated UI |
| 21st.dev | Design / UI | modern component and hero-section inspiration | helps generate premium landing pages and UI sections |
| Framer Motion | Design / Motion | animation and interaction system | powers cinematic transitions and motion polish |
| shadcn/ui | Design / Components | reusable UI primitives | foundation for admin and marketing components |
| Magic UI | Design / Motion | animated UI sections | candidate for premium marketing pages |
| Aceternity UI | Design / Motion | high-end visual effects | candidate for cinematic product storytelling |
| RAG Anything | Retrieval | multimodal document ingestion | ingests PDFs, scanned records, screenshots, images, and transcripts |
| Qdrant | Retrieval | vector memory database | stores embeddings and powers semantic search |
| Firecrawl | Web / Retrieval | structured web crawling and extraction | turns websites into structured memory and research inputs |
| Playwright CLI | Browser | browser automation and testing | powers onboarding tests, screenshots, dashboard checks, and agent web execution |
| Browser-use | Browser / Agents | browser agent workflows | candidate for autonomous web tasks |
| Whisper | Voice | speech-to-text | converts meetings, voice notes, and audio into memory |
| Piper | Voice | local text-to-speech | private voice assistant output |
| Kokoro | Voice | high-quality TTS | premium local voice workflows |
| ElevenLabs | Voice | cloud voice generation | reference/premium voice path where allowed |
| Higgsfield | Media | cinematic AI video generation | candidate for premium AI video workflows |
| Seedance | Media | AI video/motion generation | candidate for cinematic asset workflows |
| ComfyUI | Media | modular image/video generation pipeline | future local media generation orchestration |
| Flux | Media | image generation | premium visual asset generation |
| LivePortrait | Media | talking portrait generation | future avatar and assistant presentation workflows |
| FaceFusion | Media | face/media workflow tooling | candidate media pipeline tool |
| DeepEval | Evaluation | model and workflow evaluation | tests answer quality, hallucination risk, and retrieval accuracy |
| Promptfoo | Evaluation | prompt regression testing | compares prompts/models and prevents quality drift |
| GWS | Productivity | Google Workspace connection | links AI workflows to Gmail, Calendar, Docs, and Sheets |
| GitLab CE | Infrastructure / Governance | private Git, CI/CD, runners, artifacts | hosts versioned operational memory and deployment pipelines |
| Docker | Infrastructure | containerization | runs runtime services, databases, queues, and AI interfaces |
| WireGuard | Infrastructure / Network | encrypted private networking | connects workstation, runtime server, DGX Spark, Jetson Thor, VPS, and storage |

---

# Skill Layer Architecture

```text
AI Skills
   ↓
Coding + Design + Retrieval + Browser + Media + Evaluation
   ↓
Platform Runtime
   ↓
Private AI Infrastructure
   ↓
You-Sir Juan Operating Platform
```

---

# Skill Status Definitions

| Status | Meaning |
|---|---|
| Active | already used or directly planned in current architecture |
| Approved | selected for integration |
| Planned | not fully implemented but part of roadmap |
| Candidate | under consideration |
| Reference | useful pattern or optional external service |

---

# Skill Documentation Rule

Every new skill should eventually receive its own file:

```text
ai-skills/<skill-name>.md
```

Each file should document:

- description
- upstream source
- install notes
- license notes
- platform role
- implementation status
- security notes
- related feature IDs
- related PRDs
- related pain journal entries

---

# Strategic Goal

The AI skills layer should make You-Sir Juan feel like:

> one coordinated private AI operating platform,

not a pile of disconnected tools.
