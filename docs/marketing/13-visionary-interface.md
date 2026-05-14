# visionOS — Spatial AI

**Tagline:** Your Associate Agent, all around you.

---

## What it is

You-Sir Juan™ ships a visionOS 2.0 target for Apple Vision Pro. On spatial hardware, the Associate Agent moves out of the screen entirely — it exists as a living presence in your physical space, anchored in an ImmersiveSpace scene that fills your field of view.

---

## Why it matters

The kiosk is a screen on a wall. The Vision Pro is a different relationship with space entirely. When you put on the Vision Pro, your Associate Agent is no longer a 2D interface — it is a spatial presence that coexists with your environment. Ask it something. It responds from the space around you.

This is what computing looks like when the screen disappears.

---

## What the experience is

- The Associate's presence renders in an ImmersiveSpace — a full RealityKit scene that fills your spatial field
- The accent orb from the iOS interface becomes a spatial anchor — floating in the room, responding to your gaze and gestures
- Voice interaction is the same as iOS — speak, listen, respond — but the spatial audio makes it feel like a presence in the room rather than a speaker
- Your member paradigm renders at spatial scale — your colors, your Associate's character, your world — in 3D

---

## How it works technically

- `YouSirJuanVision` Xcode target: visionOS 2.0, same `Sources/` directory as iOS
- `ImmersiveSpace(id: "AvatarSpace")` scene hosts the `AvatarRealityView` at spatial scale
- `#if os(visionOS)` guards route to the ImmersiveSpace entry; `#if os(iOS)` routes to the standard window
- Same backend API, same Associate Agent system, same memory — different rendering target

---

## Current status

The visionOS target builds and compiles. The `AvatarRealityView` runs in spatial mode. Full spatial interaction design (gaze-based navigation, hand gestures, spatial audio) is Phase 3 of the interface roadmap.

---

## Who it's for

Vision Pro owners who want their Associate Agent to feel like it lives in their space. Early adopters who want to see what private AI looks like in the spatial computing era. Family offices running Vision Pro as a premium workstation.
