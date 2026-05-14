# Private Memory

**Tagline:** Your Associate never forgets. And only your family can teach it.

---

## What it is

Every conversation, every preference, every lesson you teach your Associate Agent is stored privately on your hardware. The memory persists across sessions, across reboots, across years. Context never resets. The relationship accumulates.

---

## Why it matters

Most AI interactions start from scratch every time. You explain yourself again. You re-establish context. You repeat the same preferences you've mentioned before. The AI has no memory of you.

You-Sir Juan™ is built on the opposite assumption: every exchange is remembered. Every piece of context the member shares — names, preferences, routines, household facts — becomes permanent knowledge the Associate Agent carries into every future conversation.

---

## How it works

**Conversation memory**
Every voice turn is recorded — what the member said, what the Associate responded — timestamped and appended to the member's private memory file. The most recent turns are injected as context into every new exchange.

**Training memory**
During onboarding, members teach their Associate directly: preferred name, voice preference, household facts ("we eat dinner at 7pm", "the kids' school is Lincoln Elementary"). These are stored as `training` entries — permanent household knowledge.

**Configuration memory**
Members can update their Associate's behavior at any time via the settings screen or voice command. Changes are stored as `config` entries and take effect immediately.

**Storage**
Memory is stored as JSON files in `.data/memory/{userId}.json` on the runtime node — typically the Mac mini. For households with high conversation volume, the system migrates to Postgres (included in `docker-compose.yml`). The Qdrant vector database enables semantic retrieval — the Associate can surface relevant past context even for indirect questions.

---

## Privacy

- Memory is stored locally. Never sent to any cloud.
- Each member's memory is siloed — one member cannot access another's.
- Operators can export, inspect, or delete any member's memory at any time.
- No AI training. Your household data never improves anyone else's model.

---

## Who it's for

Anyone who wants an AI relationship that gets better over time — not one that starts over every session. The longer the household uses You-Sir Juan™, the more their Associates know them. That compounding value is the core product.
