# HomeKit Integration

**Tagline:** Tell your Associate to handle the house. It already knows how.

---

## What it is

You-Sir Juan™ connects to your home's smart devices through the HomeKit bridge — a local service that translates natural-language directives from your Associate Agent into home automation commands. Speak to your Associate. The house responds.

---

## Why it matters

Smart home devices have apps. Most of those apps are fine. But switching between your AI assistant and a smart home app to dim the lights is friction. When your Associate Agent already understands your context and your requests, there is no reason it shouldn't also control your home.

The HomeKit bridge makes the Associate the single interface for everything — conversation, information, and home control — without requiring you to learn a new syntax or open another app.

---

## What it can do

| Voice command | Action |
|---|---|
| "Set the lights to evening mode" | Activates a HomeKit scene |
| "Turn off the kitchen lights" | Toggles a specific device |
| "Lock the front door" | Locks a HomeKit-connected lock |
| "Set the thermostat to 72 degrees" | Updates climate setpoint |
| "Play some music in the living room" | Sends a media command |

---

## How it works

1. Your voice turn is processed by the Associate Agent (Ollama)
2. If the response contains a home-control directive, it routes to the HomeKit bridge service (port 4002)
3. The bridge parses the intent using pattern matching — lights, locks, climate, toggle, media
4. The command is executed via the HAP-nodejs layer against your HomeKit accessories
5. The Associate confirms the action in conversation

The bridge runs locally alongside the main API — no cloud routing, no Apple HomeKit server dependency beyond your local network.

---

## Current status

**Phase 1 (live):** Intent parsing and command routing with stub device control. All five intent categories (lights, locks, climate, toggle, media) are recognized and routed. Stub responses confirm the command shape.

**Phase 2 (next):** Real HAP-nodejs accessory connections to live HomeKit devices on your home network.

---

## Who it's for

Any household with HomeKit-connected devices who wants voice control through their Associate Agent rather than through Siri or the Home app. Especially compelling for kiosk use — walk up, get authenticated, ask the house to set the mood, and step into your world. All in one interaction.
