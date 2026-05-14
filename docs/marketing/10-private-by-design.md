# Private by Design

**Tagline:** Your AI lives on your hardware. Full stop.

---

## What it is

You-Sir Juan™ is architected from the ground up for privacy. Every component that can run locally does. No conversation, no memory, no biometric data, and no household information is transmitted to any third party by default.

This is not a privacy policy. It is an architecture.

---

## The architecture guarantee

| Data | Where it lives | Who can see it |
|---|---|---|
| Conversations | Your hardware (`.data/memory/`) | Only you |
| Face biometrics | On-device only (iPad) | Never leaves the device |
| LLM inference | Your Mac mini or MacBook via Ollama | Your hardware only |
| Voice processing | On-device STT (iOS) or browser STT (web) | Local only |
| TTS synthesis | Kokoro running in Docker on your Mac mini | Local only |
| Household memory | Your hardware (file-backed or Postgres) | Local only |
| Network traffic | WireGuard encrypted mesh | Encrypted peer-to-peer |
| Model files | Pulled once to your hardware | CDN sees the pull, not inference |

**Cloud opt-in only:** If you choose to use a cloud LLM API (OpenAI, Anthropic), that traffic goes to that provider. This is always opt-in, clearly labeled, and entirely avoidable with local models.

---

## The network layer

All devices in the household connect through a WireGuard encrypted mesh. The GL.iNet Flint 2 router is the gateway. Traffic between the kiosk, the Mac mini runtime, and any other household device stays inside the encrypted tunnel.

From outside the home, no services are exposed unless explicitly configured. Default: entirely air-gapped from the internet except for model downloads.

---

## Biometric privacy

The face recognition system never stores face images or biometric embeddings. The enrollment process:
1. Captures a still frame from the kiosk camera
2. Detects face landmarks using Apple's Vision framework — on-device
3. Computes a SHA-256 hash of the landmark data + enrollment timestamp
4. Stores only the hash (an opaque token) — not the face, not the landmarks, not the image

The hash cannot be reversed to reconstruct a face. Even if the database were extracted, no biometric data is recoverable.

---

## Session security

- All API endpoints require a signed session token (HMAC-SHA256)
- Tokens expire after 8 hours
- CORS is locked to known origins
- Credentials never transmitted in plain text
- No session cookies — token-based, stateless, auditable

---

## Data ownership

The household's data belongs to the household. Operators can:
- Export all memory for any member at any time
- Delete all memory for any member
- Inspect any conversation in plain JSON
- Migrate to a new device with a single file copy

No lock-in. No data held hostage. No "contact support to delete your data."

---

## Who it's for

Anyone who takes privacy seriously — family offices with confidential operations, households with children, high-net-worth individuals who cannot afford data exposure, and anyone who has looked at the terms of service of a mainstream AI product and decided they want something different.
