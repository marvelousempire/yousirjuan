# TTS & Speech Systems

> **Live Family Office stack (June 2026):** For the deployed Super Rick configuration — every engine, model, port, and tweak — read [`docs/setup/30-voice-stack-full-undressing.md`](../docs/setup/30-voice-stack-full-undressing.md) and the canonical mirror in `marvelousempire/voice-stack` → `understandings/FULL-STACK-UNDRESSING.md`. This page remains the platform philosophy; that pair is the operational truth.

## Purpose

This document defines the text-to-speech, speech-to-text, voice assistant, transcription, and audio intelligence layer for You-Sir Juan.

The goal is to support:

- voice assistants
- spoken memory capture
- meeting transcription
- household voice workflows
- family-office briefings
- assistant narration
- local/private voice operation
- cinematic product demos
- audio-first interfaces

---

# Voice Layer Philosophy

Voice is not treated as a side feature.

Voice becomes:

> the human interface layer for private AI operations.

The system should eventually support:

- listening
- speaking
- summarizing
- remembering
- responding
- narrating
- guiding users through workflows

---

# Speech Stack

| System | Type | Purpose | You-Sir Juan Use |
|---|---|---|---|
| Whisper | Speech-to-text | local transcription | converts voice notes, calls, meetings, and audio files into searchable memory |
| Piper | Text-to-speech | local TTS | fast private voice output for assistants |
| Kokoro | Text-to-speech | higher-quality local TTS | premium local assistant voice and narration |
| ElevenLabs | Cloud voice / voice cloning | premium voice generation | optional high-quality narrated demos, onboarding, and marketing audio |
| Coqui TTS | Open-source TTS | alternate local TTS | backup/private TTS option |
| AudioCraft | AI audio generation | sound/music generation | future sound design, product demos, and media workflows |

---

# Recommended Role Split

| Need | Preferred Tool |
|---|---|
| Private local transcription | Whisper |
| Fast local assistant voice | Piper |
| Better local natural voice | Kokoro |
| Premium narrated demo voice | ElevenLabs |
| Fully open-source TTS alternative | Coqui TTS |
| Audio/music generation experiments | AudioCraft |

---

# How Voice Connects To Memory

```text
Voice Input
   ↓
Whisper Transcription
   ↓
Text Cleanup
   ↓
Chunking + Metadata
   ↓
Embedding Generation
   ↓
Qdrant Memory Store
   ↓
Assistant Retrieval
   ↓
TTS Response Through Piper / Kokoro / ElevenLabs
```

---

# Primary Use Cases

## Personal Assistant Memory

Users can speak instructions, preferences, and notes.

The system converts them into structured memory.

Examples:

- household rules
- assistant instructions
- daily routines
- family preferences
- project updates
- client notes

---

## Meeting Memory

Recordings can become:

- transcripts
- summaries
- action items
- searchable records
- assistant training data

---

## Family Office Briefings

Assistants can generate spoken briefings for:

- schedules
- priorities
- document summaries
- operational reports
- reminders

---

## Nanny / Household Assistant Workflows

Voice can support:

- spoken checklists
- child routine reminders
- household rule recall
- emergency instructions
- caregiver handoff notes

---

## Product Demos & Marketing

TTS can generate:

- narrated walkthroughs
- landing page audio
- demo videos
- explainer clips
- onboarding voiceovers

---

# Hardware Mapping

| Hardware | Voice Role |
|---|---|
| MacBook Pro M5 Max | voice workflow creation, editing, testing |
| Mac mini M4 Pro | always-on transcription, TTS service, assistant runtime |
| Jetson Thor | edge voice, robotics voice, local low-latency audio |
| DGX Spark | large model voice-agent orchestration and multimodal reasoning |
| NAS / NVMe | audio archives, transcripts, embeddings, generated voice assets |

---

# Privacy Model

Default preference:

1. Local transcription first.
2. Local TTS first.
3. Cloud voice only when explicitly approved.
4. Sensitive recordings stay local.
5. Transcripts become namespace-bound memory.

---

# Future Voice Features

Planned capabilities:

- voice assistant mode
- local wake-word support
- speaker diarization
- call transcription
- meeting summaries
- audio memory ingestion
- real-time assistant voice
- voice-based onboarding
- voice-based admin commands
- assistant voice profiles
- multilingual voice workflows

---

# Related Platform Areas

| Area | Relationship |
|---|---|
| RAG / Memory | stores transcripts and voice notes |
| Assistants | speak and listen through voice layer |
| Media Intelligence | uses narration and audio generation |
| Admin Dashboard | monitors transcription and voice jobs |
| Ingestion | processes audio files and transcripts |
| Evaluations | checks transcription and response quality |
| Hardware Mesh | routes voice workloads to correct node |

---

# Strategic Goal

The speech layer should allow You-Sir Juan to become:

> an AI system users can talk to, teach, and hear back from.

Voice turns the platform from a text-based tool into a living operational interface.
