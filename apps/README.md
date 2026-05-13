# Apps — The Family Interface MVP

Two clients, one backend. Both implement the three foundational screens from `plans/family-interface-vision.md`: **Auth → Home World → Voice**.

| Surface | Path | Stack | Purpose |
|---|---|---|---|
| Backend | `api/` | Express, Node 24 | Persona registry, sessions, voice turn, memory |
| Web client | `apps/yousirjuan-web/` | Next.js 15 + Tailwind 4 + Framer Motion | Browser/kiosk on any hardware |
| iOS client | `apps/yousirjuan-ios/` | SwiftUI + Speech + AVFoundation | iPad Pro premium kiosk |

The web app and the iOS app are **mirrors**: same flow, same three screens, same paradigm system. They both call the same backend on `localhost:4001`.

---

## Run everything (3 terminals)

### 1. Backend — `localhost:4001`

```bash
# from repo root
pnpm install
PORT=4001 pnpm dev:api
```

Smoke test:

```bash
curl http://localhost:4001/health
curl http://localhost:4001/api/identity/faces
curl -X POST http://localhost:4001/api/session \
  -H 'Content-Type: application/json' \
  -d '{"faceId":"face-avery-001"}'
```

### 2. Web client — `localhost:3000`

```bash
cd apps/yousirjuan-web
pnpm install
pnpm dev
```

Open http://localhost:3000 — you'll land on `/auth`, pick a family member, and step into their world.

### 3. iOS client — iPad Pro Simulator

```bash
cd apps/yousirjuan-ios
xcodegen generate          # regenerate the .xcodeproj from project.yml
open YouSirJuan.xcodeproj  # then ⌘R in Xcode, target an iPad Pro simulator
```

Or build headlessly:

```bash
xcodebuild -project YouSirJuan.xcodeproj \
  -scheme YouSirJuan \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

The Simulator can reach the host's `localhost:4001` directly. On a real device, set `YOUSIRJUAN_API_URL` via your scheme environment, or point it at the Mac mini's tailnet/WireGuard address.

---

## What MVP does today

- **Three enrolled "faces"** for the demo family (Avery, Morgan, Jordan), seeded in `api/src/identity.js`
- **Three distinct paradigms** seeded in `api/src/personas.js` — pick a different user and the entire UI repaints: palette, layout, label vocabulary, agent name, agent voice
- **Voice turn** is text-in / text-out with a stub reply; the client handles STT (iOS `SFSpeechRecognizer`, web `webkitSpeechRecognition`) and TTS (`AVSpeechSynthesizer`, `speechSynthesis`) locally
- **Memory** is persisted in-process for the life of the API server

## What MVP does NOT do yet (deferred)

- RealityKit 4 L2/L3 immersion (the cinematic 3D scenes from `docs/cinematic-3d-ios-prd.md`)
- 3D persona avatar rendering — the visual face of the butler
- Real LLM routing (the voice turn stub will be replaced by local Ollama in Phase 2)
- Locally-hosted TTS engine (Kokoro / similar) to honor the persona's chosen voice precisely
- WebSocket voice streaming — currently REST round-trips
- Auto face enrollment from the kiosk
- Hardware track (Pi kit, 3D-printed cases, GL.iNet bundle, Ansible playbooks)

See [`plans/family-interface-vision.md`](../plans/family-interface-vision.md) for the full phase plan.

---

## File map

```
api/
├── server.js                       # Express bootstrap, all routes wired here
└── src/
    ├── identity.js                 # face_id → user_id
    ├── personas.js                 # per-user paradigm + agent registry
    ├── session.js                  # POST /api/session
    ├── memory.js                   # GET/POST /api/memory/:userId
    └── voice.js                    # POST /api/voice/turn (stub reply)

apps/yousirjuan-web/
├── app/
│   ├── layout.tsx                  # root + SessionProvider mount
│   ├── session-provider.tsx        # client session store, applies paradigm to CSS vars
│   ├── page.tsx                    # / → routes to /auth or /home
│   ├── auth/page.tsx               # face picker, calls /api/session
│   ├── home/page.tsx               # per-paradigm home world
│   └── voice/page.tsx              # speech in/out + transcript
├── next.config.ts                  # rewrites /api/* → backend
└── package.json

apps/yousirjuan-ios/
├── project.yml                     # xcodegen spec → YouSirJuan.xcodeproj
├── Sources/
│   ├── App/                        # YouSirJuanApp, RootView
│   ├── Models/Persona.swift        # mirrors the backend schema
│   ├── Services/
│   │   ├── API.swift               # URLSession client
│   │   ├── SessionStore.swift      # @MainActor ObservableObject
│   │   └── Speech.swift            # AVSpeechSynthesizer bridge
│   ├── Support/Color+Hex.swift     # hex → SwiftUI Color
│   └── Views/
│       ├── AuthView.swift
│       ├── HomeWorldView.swift
│       └── VoiceView.swift
└── Info.plist                      # FaceID + mic + speech recognition usage strings
```
