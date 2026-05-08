# System Architecture Diagrams

# Core Platform Flow

```text
Customer
   ↓
Assistant Interface
   ↓
Open WebUI / OpenClaw
   ↓
Ruflo Orchestration Layer
   ↓
Memory Retrieval
   ↓
Ollama / Local Models
   ↓
LLM Response
```

---

# Relationship Memory Flow

```text
Documents
Notes
Schedules
Transcripts
Handbooks
Preferences
        ↓
Chunking
        ↓
Embeddings
        ↓
Vector Database
        ↓
Namespaces
        ↓
Assistant Retrieval
        ↓
AI Response
```

---

# Trust Domain Separation

```text
Family Office
    ↓
fo:*
    ↓
ISOLATED

PMA
    ↓
pma:*
    ↓
SEPARATED

Portfolio Businesses
    ↓
{biz}:*
    ↓
OPTIONAL SHARED LAYERS

Shared Layer
    ↓
shared:playbooks:wins
shared:playbooks:failures
shared:vendors:approved
```

---

# Home Infrastructure

```text
Internet
    ↓
Flint 2 Router
    ↓
Tailscale / WireGuard
    ↓
Mac mini
    ↓
Ollama
    ↓
Ruflo
    ↓
Jetson Thor
    ↓
NAS / DAS
```

---

# Travel Architecture

```text
Laptop / iPad
      ↓
Slate AX
      ↓
Encrypted Tunnel
      ↓
Home Flint 2
      ↓
Home AI Infrastructure
```

---

# AI Stack Layers

```text
Models
  ↓
Runtimes
  ↓
Agents
  ↓
Memory
  ↓
Networking
  ↓
Infrastructure
```

---

# Long-Term Platform Direction

```text
Private AI Models
        ↓
Persistent Relationship Memory
        ↓
Autonomous Assistants
        ↓
Operational Intelligence
        ↓
Secure Infrastructure
        ↓
Embodied AI / Robotics
```
