# Plan: Family Interface — Product Vision & Build Roadmap

## Context

You-Sir Juan™ is expanding beyond private AI infrastructure into a consumer-facing product: a premium iOS/iPadOS operating system interface for families running their own home AI. The market timing is May 2026 — ahead of the mainstream wave of people buying Mac minis and high-end Macs specifically to run local AI. Affluent markets (Miami, etc.) are early adopters. The product fills a gap that mass-market voice assistants cannot: a private, family-trainable AI that learns a specific household's customs, culture, language, and priorities — and belongs entirely to that family.

---

## Work Completed

### README Updates (done)

Two new sections added to `README.md`:

**1. "Yours to Train"** — the product's market differentiator, inserted between Executive Summary and The Interface. Positions against generic always-on voice assistants (without naming them) and establishes the core thesis: your family trains it, owns it, and no one else touches it.

**2. "The Interface"** — the full UX vision for the family office kiosk layer:
- Walk-up 21" touchscreen kiosk (iPad Pro-class)
- Touchless biometric auth: face recognition → fingerprint 2FA, all on-device
- Personalized world per user: same functions, different form (colors, labels, layout, language, mood)
- Personal AI agent / butler: persistent persona with user-chosen voice, acts as intermediary to all platform data and systems, never resets memory
- Voice-first conversation: speech-to-speech primary, text fallback
- Onboarding: pre-seeded profile → voice selection → paradigm adaptation → memory begins

---

## Product Vision (to build)

### The Consumer Product

A native iOS/iPadOS app that ships as the operating interface for any family's home AI system. Not a utility — a living environment. The app is the face of the AI and the portal to everything the platform knows and can do.

**Target hardware:** iPad Pro (wall-mounted or countertop), iPhone as secondary access point.

**Target users:** Families who own Mac mini M4 Pro or MacBook Pro M5 Max for local AI — a segment growing rapidly in 2026.

### The Visual System

Built on the existing `docs/cinematic-3d-ios-prd.md` ("RealityMotion") spec:

| Capability | Implementation |
|---|---|
| Rendering | RealityKit 4 + Metal, 120fps |
| UI depth | Z-space perspective, layered 3D scenes |
| Motion | Physics-based gestures (ManipulationComponent, PhysicsBodyComponent), Framer-quality transitions |
| 3D controls | ViewAttachmentComponent (SwiftUI controls embedded in 3D space) |
| Immersion levels | L1: SwiftUI only / L2: Hybrid RealityView heroes / L3: Full physics scene |

### The AI Persona / Butler

Each user has a 3D-rendered AI persona — the visual presence of their personal agent:
- Photorealistic face (locally generated and hosted) or stylized 3D avatar
- User-selectable appearance during onboarding
- Persona speaks responses aloud in user-chosen voice (local TTS)
- Lives in the interface as a real presence, not a chat bubble
- The persona's visual style, voice, and name are all shaped by the user at setup

---

## Build Phases

### Phase 1 — iOS App Foundation
- Xcode project scaffolding: SwiftUI + RealityKit 4 target
- Design token system from `docs/cinematic-3d-ios-prd.md` (colors, typography, spacing, motion curves)
- L1 screens: biometric auth flow, home screen, voice input UI
- Local TTS integration (Kokoro or equivalent, hosted on Mac mini)

### Phase 2 — Personal Agent Layer
- WebSocket or gRPC bridge from iOS app → You-Sir Juan™ backend API
- Per-user agent routing: face ID → user record → agent context loaded
- Voice pipeline: on-device STT → agent → TTS → audio output
- Persistent memory: every session appended to user's agent context

### Phase 3 — Cinematic UI & Persona
- RealityKit 4 L2/L3 scenes: Z-space depth, physics, immersive transitions
- 3D persona renderer: avatar lives in RealityView, lip-syncs to TTS output
- Per-user visual paradigm: color palette, layout, and label set derived from user profile
- Persona customization UI: face/avatar selection, voice selection, name assignment

### Phase 4 — Family Training Layer
- In-app training flows: teach the agent names, preferences, customs, recurring tasks
- Family vocabulary layer: user-defined terms, nicknames, cultural context stored in agent memory
- Privacy controls: each user's training data is silo'd, never shared across families

---

## Key Files

| File | Purpose |
|---|---|
| `README.md` | Product vision — updated with The Interface + Yours to Train sections |
| `docs/cinematic-3d-ios-prd.md` | RealityMotion design system PRD — approved, awaiting implementation |
| `PRD.md` | Platform-level product requirements |
| `OPERATING-SYSTEM-LEAD-SHEET.md` | Hardware roles and deployment layer specs |
| `apps/` | iOS app will live here |
| `api/` | Backend API the iOS app connects to |
| `assistants/` | Per-user agent definitions and persona configs |

---

## Verification

When Phase 1 ships:
1. App launches on iPad Pro, displays biometric auth screen
2. Face ID identifies user, Touch ID confirms, home screen loads
3. User can speak to agent, agent responds via TTS in chosen voice
4. Session history persists across app restarts

When Phase 3 ships:
1. 3D persona is visible in RealityView, responds with motion to voice
2. UI paradigm (colors, labels, layout) differs visibly between two test users
3. Z-space depth and physics transitions run at 120fps on M-series hardware
