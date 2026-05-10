# Ethics and Apple Device Sensor Doctrine

You-Sir Juan™ is designed to become a private AI infrastructure platform that can benefit from the capabilities of personal Apple devices while preserving consent, dignity, privacy, and user control.

This document defines the ethical boundary for using sensors and device signals from:

- iPhone
- Apple Watch
- iPad
- Apple TV
- MacBook
- Mac mini
- future Apple ecosystem devices

---

## Core Principle

Device intelligence must serve the user, not watch the user.

The platform may use device capabilities to improve:

- safety
- context awareness
- accessibility
- automation
- health-supportive routines
- home and family continuity
- local AI assistance
- operational memory

but it must not become a hidden surveillance system.

---

## Ethical Rules

## 1. Consent First

No sensor, location, camera, microphone, Bluetooth, health, motion, or nearby-device signal should be used unless the user clearly allows it.

The system should support:

- opt-in consent
- per-device consent
- per-sensor consent
- easy revoke controls
- visible status indicators
- clear explanations of what each signal is used for

---

## 2. Local First

Device signals should be processed locally whenever possible.

Preferred order:

1. process on-device
2. process on trusted local network
3. process on private self-hosted infrastructure
4. send externally only with explicit user approval

---

## 3. Minimum Necessary Data

The system should collect the least amount of data needed to complete the task.

Examples:

- use motion state instead of raw accelerometer history when possible
- use room presence instead of exact GPS when possible
- use event labels instead of full sensor streams when possible
- use local face recognition result instead of storing face images when possible

---

## 4. No Hidden Surveillance

The system must not secretly record, track, identify, or profile people.

Prohibited by default:

- silent microphone recording
- silent camera recording
- covert location tracking
- hidden Bluetooth tracking
- biometric collection without consent
- passive face scanning of guests without notice
- emotional profiling without consent
- sharing sensor data with third parties by default

---

## 5. User Owns the Memory

All device-derived memory belongs to the user or authorized household / organization.

The user should be able to:

- view what was stored
- delete stored memory
- pause memory collection
- export records
- turn off categories of memory
- separate household, personal, business, and trust contexts

---

## 6. Safety and Dignity

Sensor data should be used to support human dignity.

Valid uses include:

- fall detection workflows
- emergency routines
- medication reminders
- task reminders
- accessibility support
- elder care support
- child-safe routines
- home automation
- device handoff
- private productivity flows

Invalid uses include:

- manipulation
- coercion
- secret monitoring
- unauthorized tracking
- behavioral exploitation
- invasive profiling

---

# Apple Device Capability Map

## iPhone

Potential signals and strengths:

- accelerometer
- gyroscope
- GPS / location
- Bluetooth proximity
- Wi-Fi context
- camera
- LiDAR on supported models
- Face ID capability boundary
- microphone
- NFC
- barometer
- magnetometer / compass
- notifications
- Shortcuts automations
- Focus modes
- Health app integrations when authorized

Potential You-Sir Juan™ uses:

- private context awareness
- motion-aware automations
- location-based reminders
- local device handoff
- room / home presence logic
- document scanning workflows
- visual capture with consent
- emergency routine triggers
- Apple Shortcuts integration
- voice-to-agent workflows

Ethical boundary:

- no silent recording
- no unauthorized location history
- no covert face or object scanning
- no third-party sharing by default

---

## Apple Watch

Potential signals and strengths:

- heart rate
- motion
- fall detection
- workout state
- sleep signals
- wrist presence
- emergency SOS
- haptics
- voice input
- timers and reminders
- health-related events when authorized

Potential You-Sir Juan™ uses:

- wellness reminders
- routine support
- fall-response workflows
- haptic alerts
- private voice commands
- household safety triggers
- focus / work session state
- elder support workflows

Ethical boundary:

- health data must be opt-in
- health data should remain local where possible
- no diagnosis claims
- no medical replacement claims
- no coercive monitoring

---

## iPad

Potential signals and strengths:

- large touchscreen interface
- camera
- microphone
- Apple Pencil input
- LiDAR on supported models
- document scanning
- local dashboards
- shared household control panel
- Sidecar / continuity workflows

Potential You-Sir Juan™ uses:

- command dashboard
- family-office interface
- trust records review
- document ingestion station
- visual planning board
- whiteboard-to-agent workflows
- room-based assistant terminal

Ethical boundary:

- visible capture only
- clear household mode vs personal mode
- no hidden camera or microphone workflows

---

## Apple TV

Potential signals and strengths:

- shared-room screen
- media control
- HomeKit presence context
- remote input
- family dashboard display
- video display
- notifications
- room-level interface

Potential You-Sir Juan™ uses:

- household dashboard
- family briefing board
- local AI status screen
- calendar and reminder display
- home operations dashboard
- Apple Home routines

Ethical boundary:

- shared-screen content must respect privacy
- personal records should not appear on shared displays without approval
- household mode must be separate from private mode

---

## Mac mini

Potential strengths:

- always-on local server
- Docker services
- Ollama / Open WebUI
- vector databases
- local APIs
- file ingestion
- device sync hub
- backups
- logs
- network services
- HomeKit / Shortcuts bridge

Potential You-Sir Juan™ uses:

- local AI server
- private RAG server
- memory and retrieval host
- local automation gateway
- skill library host
- device signal broker
- private dashboard backend
- model router

Ethical boundary:

- the Mac mini should act as a trusted local hub
- it should not collect device signals without consent
- logs must be visible and purgeable
- sensitive data should be encrypted at rest

---

## MacBook

Potential strengths:

- primary operator workstation
- local development
- coding agents
- document preparation
- fine-tuning experiments
- private command center
- mobile AI operations

Potential You-Sir Juan™ uses:

- development environment
- private coding workflows
- local model testing
- document generation
- trust operations dashboard
- human approval station

Ethical boundary:

- operator remains in control
- destructive automations require approval
- repo changes require review
- local logs must not leak secrets

---

# Device Signal Broker Concept

You-Sir Juan™ should use a device signal broker rather than raw uncontrolled sensor access.

The broker converts device signals into safe, permissioned events.

Example:

```text
Raw GPS stream
    ↓
Permissioned location zone event
    ↓
"User arrived home"
```

Example:

```text
Raw accelerometer stream
    ↓
Motion classification
    ↓
"Possible fall detected"
```

Example:

```text
Camera / LiDAR frame
    ↓
On-device interpretation
    ↓
"Document scan ready"
```

The platform should prefer meaningful events over raw surveillance data.

---

# Event Categories

Allowed event categories may include:

- presence events
- routine events
- safety events
- task events
- document capture events
- automation events
- health-supportive events with consent
- accessibility events
- device handoff events

Restricted event categories include:

- biometric events
- exact location events
- microphone events
- camera events
- health events
- child / guest events

Restricted events require stronger consent and clearer logging.

---

# Required Controls

The system should eventually include:

- sensor permissions dashboard
- per-device trust level
- per-sensor toggle
- local audit log
- privacy mode
- household mode
- business mode
- guest mode
- emergency mode
- data retention rules
- delete/export controls

---

# Consent Levels

| Level | Meaning | Example |
|---|---|---|
| Off | No access | GPS disabled |
| Event Only | Derived events only | arrived home |
| Local Raw | raw data processed locally only | motion stream for fall detection |
| Stored Local | local memory allowed | daily routine record |
| External Allowed | external API use allowed | user-approved cloud analysis |

Default should be:

```text
Off unless enabled.
```

---

# Privacy Modes

## Private Mode

Only the individual user can see personal data.

## Household Mode

Shared home data may appear on shared dashboards.

## Business Mode

Only business-context data is available.

## Trust / PMA Mode

Only authorized trust or PMA operational records are accessible.

## Guest Mode

Guest data is not stored by default.

---

# Development Rule

Any feature using device sensors must answer these questions before implementation:

1. What data is being accessed?
2. Why is it needed?
3. Can it be converted into an event instead of storing raw data?
4. Where is it processed?
5. Where is it stored?
6. How can the user revoke access?
7. How can the user delete it?
8. Who can see it?
9. What happens in guest mode?
10. What is the abuse risk?

---

# Final Standard

The Apple device ecosystem should become a strength of You-Sir Juan™ because it can provide private, local, contextual intelligence.

But the standard is clear:

> Intelligence must remain consent-based, local-first, explainable, revocable, and user-owned.
