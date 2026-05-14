# Voice-First Conversation

**Tagline:** Speak. Listen. Done. The interface that talks back.

---

## What it is

The primary mode of interaction with You-Sir Juan™ is speech-to-speech. You speak to your Associate Agent. The Agent listens, processes, and responds aloud — in the voice you chose, with the context of your full relationship history. No typing required.

---

## Why it matters

Typing is a workaround. The most natural way to interact with someone you trust is to speak to them. Your Associate Agent is designed to be that presence — not a search bar, not a command prompt, but a conversation partner that knows you.

Voice-first also means hands-free. You can ask your Associate to check the household calendar, brief you on the day, or control your home while you're making coffee, getting dressed, or walking through the door.

---

## How it works

**Speaking**
- On iOS: `SFSpeechRecognizer` captures and transcribes your voice on-device
- On the web: Web Speech API (Chrome/Safari) handles STT in the browser
- Both operate entirely locally — your voice is never sent to a third-party STT service

**Processing**
- The transcribed text routes to the backend voice turn endpoint
- Ollama (local LLM) processes the request with your Associate's full persona and memory context injected
- Response is generated locally — no cloud inference by default

**Responding**
- On iOS: `AVSpeechSynthesizer` speaks the response in your Associate's configured voice profile
- Via Docker: Kokoro TTS (locally hosted) delivers higher-quality neural speech for all surfaces
- The voice is consistent every time — chosen at setup, owned by you

**Barge-in**
The WebSocket voice channel supports interruption. If you speak mid-response, the in-flight generation is cancelled and your new utterance is processed immediately. The conversation flows naturally.

---

## Text fallback

Not in a place where you can speak? A text input field is always available on both iOS and web. Everything typed routes through the same Associate Agent — same persona, same memory, same response quality.

---

## Who it's for

Anyone who wants to interact with their home AI the way they interact with a person — naturally, conversationally, without friction. Especially powerful for hands-free use: kitchen, garage, home office, front door.
