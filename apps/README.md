# Apps — The Family Interface

Two clients, one backend. Both deliver the full Associate Agent experience: biometric auth, personalized world, voice-first conversation.

| Surface | Path | Stack | Port |
|---|---|---|---|
| Backend API | `api/` | Express + Node.js, Postgres, Redis, Qdrant, Ollama | `4000` |
| Web client | `apps/yousirjuan-web/` | Next.js 15 + Tailwind 4 + Framer Motion | `3000` |
| iOS client | `apps/yousirjuan-ios/` | SwiftUI + RealityKit 4 + AVFoundation | iPad/Simulator |

---

## Quick start (3 terminals)

### 1. Backend — `localhost:4000`

```bash
# from repo root
pnpm install
pnpm dev:api
```

Smoke tests:

```bash
curl http://localhost:4000/health
curl http://localhost:4000/api/identity/faces
curl -X POST http://localhost:4000/api/session \
  -H 'Content-Type: application/json' \
  -d '{"faceId":"face-avery-001"}'
```

### 2. Web client — `localhost:3000`

```bash
cd apps/yousirjuan-web
pnpm install
pnpm dev
```

Open http://localhost:3000 → `/auth` → pick a family member → step into their world.

> **Port conflict?** If port 3000 is taken: `pnpm dev -- -p 3002`

### 3. iOS client — iPad Pro Simulator

```bash
cd apps/yousirjuan-ios
xcodegen generate
open YouSirJuan.xcodeproj   # ⌘R → iPad Pro 13" (M5) simulator
```

Headless build:

```bash
xcodebuild -project YouSirJuan.xcodeproj \
  -scheme YouSirJuan \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

On a real device: set `YOUSIRJUAN_API_URL` in the scheme environment to the Mac mini's Tailscale/WireGuard IP.

### 4. Full Docker stack (recommended)

```bash
# from repo root — starts Ollama, Postgres, Redis, Qdrant, Kokoro TTS, nginx
docker compose up -d
```

Without Docker: the API runs in stub/file-backed mode. Voice turns need `docker compose up ollama` or Ollama installed natively.

---

## The four Associate Agents

Each family member has a distinct visual world and a named Associate Agent. Switching users repaints the entire interface.

| Face ID seed | Member | Associate | Accent | Paradigm |
|---|---|---|---|---|
| `face-avery-001` | Avery Goodman | Sterling | `#7C5CFF` Obsidian | executive-grid / serif |
| `face-bobby-001` | Robert Bobby | Blake | `#FF6B35` Copper | soft-stack / humanist |
| `face-nivram-001` | NIVRAM | Cipher | `#00FF88` Matrix | developer-dense / mono |
| `face-yousirjuan-001` | Yousir Juan | Full | `#FFD700` Gold | command-center / display |

---

## What's built

### Backend (`api/`)
- HMAC session tokens — `POST /api/session` validates face ID, returns signed token
- Ollama LLM — `POST /api/voice/turn` routes to local llama3.2:3b (stub fallback if Ollama is offline)
- WebSocket voice channel — `ws://localhost:4000/api/voice/ws` with barge-in cancellation
- File-persisted memory — `.data/memory/{userId}.json`, survives restarts
- SSE paradigm sync — `GET /api/sync/:userId` streams live paradigm updates across devices
- Train-associate onboarding — `POST /api/onboard/:userId` saves name, voice, household lessons
- Face enrollment — `POST /api/identity/enroll`
- Paradigm editor — `PATCH /api/personas/:userId` updates palette/mood, broadcasts SSE event
- WebAuthn challenge — `GET /api/auth/webauthn/challenge`
- HomeKit bridge — `services/homekit-bridge/` on port 4002 (lights, locks, climate, media)
- **Jest: 18/18 passing** (`pnpm test`)

### Web (`apps/yousirjuan-web/`) — 7 routes

| Route | What it does |
|---|---|
| `/auth` | Face picker + WebAuthn passkey button |
| `/onboard` | 4-step train-your-associate first-run flow |
| `/home` | Per-paradigm world + SSE live sync + gear → settings |
| `/settings` | Paradigm editor — accent swatches, mood picker |
| `/voice` | Speech-to-speech with authenticated fetch |
| `/` | Redirects to `/auth` or `/home` |

### iOS (`apps/yousirjuan-ios/`) — iOS 18 + visionOS 2

| File | What it does |
|---|---|
| `AvatarRealityView.swift` | RealityKit 4 L2 — floating accent orb, pulsing presence |
| `EnrollView.swift` | AVCaptureSession + Vision face detection → SHA-256 face ID |
| `KioskMode.swift` | Guided Access lock on iPad when unauthenticated |
| `ParadigmIcon.swift` | SF Symbols mapped per paradigm × 5 icon kinds |
| `Speech.swift` | Precise voice identifier lookup (Evan / Aaron / Samantha / Tom) |
| `YouSirJuanVision` target | visionOS 2.0 ImmersiveSpace — ready to deploy |
| `YouSirJuanTests/` | PersonaTests + APITests |

---

## File map

```
api/
├── server.js                       # Express + http.Server (WebSocket attached)
└── src/
    ├── auth.js                     # HMAC token issue + requireAuth middleware
    ├── identity.js                 # face_id → user_id registry
    ├── ollama.js                   # Ollama LLM client with persona system prompts
    ├── personas.js                 # 4 Associate Agents + paradigm registry
    ├── memory.js                   # file-persisted per-user memory
    ├── voice.js                    # POST /api/voice/turn
    ├── ws-voice.js                 # WebSocket voice + barge-in
    └── session.js                  # session utilities

apps/yousirjuan-web/
├── app/
│   ├── layout.tsx                  # root + SessionProvider
│   ├── session-provider.tsx        # session store + authFetch + CSS var injection
│   ├── page.tsx                    # / → /auth or /home
│   ├── auth/page.tsx               # face picker + WebAuthn passkey
│   ├── onboard/page.tsx            # train-your-associate 4-step flow
│   ├── home/page.tsx               # per-paradigm world + SSE sync
│   ├── settings/page.tsx           # paradigm editor
│   ├── voice/page.tsx              # speech-to-speech transcript
│   └── lib/paradigm-icons.ts       # icon map: 5 paradigms × 5 kinds
├── e2e/                            # Playwright tests
└── package.json

apps/yousirjuan-ios/
├── project.yml                     # xcodegen spec — iOS 18 + visionOS 2 targets
├── Sources/
│   ├── App/                        # YouSirJuanApp (Guided Access + visionOS ImmersiveSpace)
│   ├── Models/Persona.swift
│   ├── Services/
│   │   ├── API.swift               # URLSession client + enrollFace
│   │   ├── KioskMode.swift         # Guided Access wrapper
│   │   ├── SessionStore.swift      # @MainActor session + transcript
│   │   └── Speech.swift            # precise voice identifier lookup
│   ├── Support/
│   │   ├── Color+Hex.swift
│   │   └── ParadigmIcon.swift      # SF Symbols per paradigm
│   └── Views/
│       ├── AuthView.swift          # face grid + enrollment long-press
│       ├── AvatarRealityView.swift # RealityKit 4 L2 avatar scene
│       ├── EnrollView.swift        # face enrollment (Vision + AVCapture)
│       ├── HomeWorldView.swift     # per-paradigm home world
│       └── VoiceView.swift         # speech I/O + transcript bubbles
└── YouSirJuanTests/
    ├── PersonaTests.swift
    └── APITests.swift

services/
└── homekit-bridge/                 # HomeKit intent bridge (port 4002)

db/
└── migrations/001_schema.sql      # Postgres schema (auto-run by docker compose)
```

---

## Environment variables

Copy `.env.example` → `.env`:

| Var | Default | Notes |
|---|---|---|
| `PORT` | `4000` | API port |
| `SESSION_SECRET` | *(must change)* | HMAC signing key |
| `OLLAMA_URL` | `http://localhost:11434` | Mac mini (floor) or DGX Spark (ceiling) |
| `OLLAMA_MODEL` | `llama3.2:3b` | `llama3.3:70b` on DGX Spark |
| `KOKORO_URL` | `http://localhost:8880` | Local TTS (docker compose) |
| `YOUSIRJUAN_API_URL` | `http://localhost:4000` | iOS real-device URL (Tailscale IP) |

---

## Tests

```bash
# Backend (Jest) — from repo root
pnpm test

# Web e2e (Playwright)
cd apps/yousirjuan-web && pnpm test:e2e
```
