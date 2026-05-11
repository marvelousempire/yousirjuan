# Product Requirements Document (PRD)

## Premium Cinematic 3D UI/UX Design System for iOS Apps

## “RealityMotion” – Interconnected, Game-Like, Hyper-Realistic Interfaces

**Version:** 1.0  
**Date:** May 10, 2026  
**Author:** Grok (synthesized from collaborative discussion with Harper, Benjamin, Lucas)  
**Status:** Approved for AI-assisted implementation and prototyping

---

## Table of contents

1. [Executive Summary](#1-executive-summary)  
2. [Vision & Product Goals](#2-vision--product-goals)  
3. [Target Users & Personas](#3-target-users--personas)  
4. [Design Aesthetic, Motif & Experience](#4-design-aesthetic-motif--experience-form--function)  
5. [Functional Requirements](#5-functional-requirements)  
6. [Non-Functional Requirements & Performance Strategy](#6-non-functional-requirements--performance-strategy)  
7. [Technical Architecture](#7-technical-architecture)  
8. [Risks & Mitigations](#8-risks--mitigations)  
9. [AI Handoff Sheet / Development Handoff](#9-ai-handoff-sheet--development-handoff)  
10. [Scope, Assumptions & Out of Scope](#10-scope-assumptions--out-of-scope)  
11. [User Journeys & Critical Flows](#11-user-journeys--critical-flows)  
12. [Screen & Component Inventory (Backlog)](#12-screen--component-inventory-backlog)  
13. [Design Tokens, Motion & Haptics](#13-design-tokens-motion--haptics)  
14. [Accessibility, Inclusion & Reduced Motion](#14-accessibility-inclusion--reduced-motion)  
15. [Privacy, Security & Data in 3D Context](#15-privacy-security--data-in-3d-context)  
16. [QA, Instrumentation & Acceptance Criteria](#16-qa-instrumentation--acceptance-criteria)  
17. [Phased Delivery Roadmap (Immersion L1 → L3)](#17-phased-delivery-roadmap-immersion-l1--l3)  
18. [Open Questions & Decision Log](#18-open-questions--decision-log)  
19. [References & Canonical Apple Sources](#19-references--canonical-apple-sources)  
20. [Appendices](#20-appendices)

---

## 1. Executive Summary

This PRD defines a premium, native iOS design system and implementation strategy that elevates standard mobile UIs into cinematic, physics-driven, interconnected 3D experiences. It draws directly from the full conversation history: starting with modern cross-platform “skins” (Flutter/React Native + shadcn/ui ports), transitioning through Framer Motion-style cinematic heroes and micro-interactions, and culminating in native SwiftUI + RealityKit for hyper-realistic, game-like depth that feels alive on the latest iPhones (A18/A19 series).

The aesthetic marries **shadcn/ui’s clean, minimal, accessible, Tailwind-inspired minimalism** with **Framer Motion’s spring physics, parallax, and cinematic entrances** — then explodes it into **full 3D interconnected environments** using RealityKit. Elements connect via real physics joints, react to device tilt/gestures, embed SwiftUI controls directly in 3D space, and deliver photorealistic PBR rendering, particles, lighting, and spatial audio — all while maintaining buttery 120 fps performance and zero perceived load.

**Core Motif:** “Form follows immersive function.” Clean 2D cards and components become floating 3D objects that snap, bounce, connect, and respond as if part of a living spatial dashboard or hero world. The result feels like a $10k–$20k high-end Framer/Three.js website — but native, performant, and future-proof for iOS, iPadOS, and visionOS.

**Strategic Goal:** Create apps that stand out in the App Store as “next-gen” without relying on heavy third-party engines (Unity/Unreal) or web hybrids. Leverage Apple’s latest WWDC25 RealityKit + SwiftUI integrations for maximum hardware synergy.

---

## 2. Vision & Product Goals

- **Vision:** Every screen feels like stepping into a cinematic 3D environment where UI elements are alive, interconnected, and responsive — delivering delight, immersion, and premium perceived quality.
- **Business Objectives:**
  - Differentiate iOS apps in competitive categories (SaaS dashboards, creative tools, e-commerce heroes, onboarding, spatial experiences).
  - Achieve 120 fps smoothness and <5% battery impact on Pro devices.
  - Enable rapid iteration via Claude + UI/UX Pro Max skill for code generation.
  - Support seamless 2D ↔ 3D hybrid (start simple, scale to full immersive).
- **Success Metrics:**
  - User delight scores (NPS > 80).
  - App Store “beautiful UI” reviews.
  - Frame rate ≥ 60 fps (120 fps on Pro) across devices.
  - App size increase < 10–15 MB for 3D assets.

**Non-goals (product):** Replacing core business logic with 3D; shipping 3D on every screen by default; requiring users to learn game-like controls for routine tasks.

---

## 3. Target Users & Personas

- **Primary:** Design-forward developers/teams building premium iOS apps (SaaS, productivity, creative, fintech dashboards).
- **Secondary:** End-users who expect Apple-level polish but crave “wow” moments (e.g., cinematic product heroes, spatial onboarding).
- **Pain Points Addressed:** Flat SwiftUI feels dated; Framer Motion web is beautiful but not native/mobile-performant; heavy 3D engines add bloat.

### 3.1 Persona sketches (for scenario testing)

| Persona | Goal | RealityMotion hook |
|--------|------|---------------------|
| **Harper — Design lead** | Coherent system across marketing + app; accessible | Token-aligned 2D + optional 3D heroes; design-review checklist |
| **Benjamin — iOS engineer** | Ship fast, no engine baggage | SwiftUI + RealityKit only; lazy assets; feature flags per immersion level |
| **Lucas — Product / growth** | Differentiation + conversion | Cinematic onboarding + dashboard hero; A/B 2D vs hybrid |

---

## 4. Design Aesthetic, Motif & Experience (Form + Function)

**Core Aesthetic Pillars (shadcn/ui + Framer Motion + RealityKit):**

- **Minimal & Accessible Foundation:** Neutral palettes, subtle borders, generous whitespace, high contrast (exactly like shadcn/ui). Use UI/UX Pro Max skill’s shadcn/ui + SwiftUI support for component tokens.
- **Cinematic Motion Layer:** Spring physics (.bouncy, .snappy), parallax on scroll/tilt, keyframe-driven entrances/exits, micro-interactions (hover → lift → connect).
- **3D Interconnected Motif:** Elements exist in shared 3D space — cards as rigid bodies with joints, physics collisions, particle connections, real-time lighting/shadows reacting to device motion or environment. “Everything connects like a game.”
- **Immersion Spectrum:**
  - **Level 1:** 2D SwiftUI with subtle 3D accents (RealityKit embeds).
  - **Level 2:** Hybrid RealityView heroes with ViewAttachmentComponent (SwiftUI controls floating in 3D).
  - **Level 3:** Full interconnected scene with ManipulationComponent, custom physics systems, and spatial audio.
- **Typography & Color:** 57+ font pairings and 161 palettes from UI/UX Pro Max skill. Dark mode first, with environment-based lighting.
- **Accessibility:** Dynamic Type, VoiceOver support for 3D entities, reduced motion fallback.

### 4.1 Experience principles (non-negotiable)

1. **Progressive enhancement:** Every feature must work in **2D + Reduced Motion**; 3D is additive.  
2. **Performance budget first:** If the scene fails Instruments, simplify — never ship slideshow UI.  
3. **One focal 3D moment per screen:** Avoid competing heroes; support scanning and task completion.  
4. **Native affordances:** Prefer system haptics, sheets, and navigation over custom chrome unless it carries the motif.

---

## 5. Functional Requirements

- **Cinematic Heroes:** Parallax scroll-driven 3D scenes with spring entrances, physics bounces, and gesture manipulation.
- **Interconnected Elements:** PhysicsBodyComponent + joints so UI objects connect, react, and influence each other (e.g., dashboard cards that “link” on tilt).
- **Hybrid UI:** ViewAttachmentComponent, GestureComponent, PresentationComponent for embedding native SwiftUI controls directly on 3D entities.
- **Observable Entities:** Bidirectional data flow — SwiftUI `@Observable` / observation drives RealityKit and vice versa.
- **Animations & Interactions:** KeyframeAnimator + RealityKit timelines, ManipulationComponent for natural drag/rotate/throw, device motion parallax.
- **Asset Workflow:** USDZ / `.reality` files authored in Reality Composer Pro or Blender; lazy-loaded; versioned like any other asset.
- **Fallbacks:** Graceful degradation on non-Pro devices; pure SwiftUI springs when 3D is disabled or unavailable.
- **State & navigation:** Deep links and state restoration must not break when toggling immersion level or loading assets async.
- **Content pipeline:** Documented export settings (units, scale, pivot) and naming for USDZ; source art archived for rebuilds.

---

## 6. Non-Functional Requirements & Performance Strategy

- **Target Hardware Leverage (2026 iPhones):** A18/A19 GPU/Neural Engine for real-time PBR, physics, particles. LiDAR for environment occlusion/lighting on Pro models. 120 Hz ProMotion + haptics for ultra-responsive feel.
- **Performance Budget:**
  - ≤100k triangles in view (safe for 120 fps).
  - Use MeshInstancesComponent, LOD, instancing.
  - Profile with Xcode Instruments + RealityKit Trace.
  - GPU-limited? Reduce DOF, shadows, complex materials.
  - Lazy load, clip planes, disable expensive effects on older devices.
- **App Size & Battery:** Minimal impact; RealityKit is Metal-optimized; monitor thermal throttling during long sessions.
- **Cross-Platform Note:** Core logic shareable via Swift; future visionOS extension natural.

### 6.1 Device tiers (recommended)

| Tier | Examples | Default immersion | Notes |
|------|-----------|-------------------|--------|
| **A** | Latest Pro, 120 Hz | L2–L3 eligible | Full effects; motion parallax on |
| **B** | Standard current-gen | L1–L2 | Fewer particles; simpler materials |
| **C** | N–2 generations / thermally stressed | L1 only | No continuous physics; static 3D or none |

---

## 7. Technical Architecture

- **Primary Stack:** SwiftUI + RealityKit (`RealityView` as the bridge).
- **No UIKit fallback required for layout** — prefer SwiftUI; use UIKit only where an Apple API still requires it (document exceptions).
- **Authoring Tools:** Reality Composer Pro (visual timelines/physics), Blender → USDZ export.
- **Code Generation:** Claude + **UI/UX Pro Max** skill (SwiftUI + motion + layout prompts); keep human review for physics and GPU cost.
- **Dependencies:** RealityKit (built-in), optional **Rive** for lighter 2.5D layers where full RealityKit is overkill.
- **Modularity:** Feature-flag immersion per screen; shared `ImmersiveCapability` gate (device + user prefs + battery).
- **Testing:** Unit-test pure Swift models; UI tests run with 3D disabled or L1 for stability on CI simulators.

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance on older devices | Churn, bad reviews | Tier table + runtime caps + L1 fallback |
| Learning curve for team | Slow shipping | AI handoff prompts + Composer Pro templates |
| Asset complexity / bad exports | Crashes, z-fighting, huge binaries | Poly/texture budgets; asset review checklist |
| Accessibility gaps | Exclusion, App Store risk | VO labels on entities; RM reduces to 2D |
| Scope creep (“3D everything”) | Slipped milestones | §10 scope + one focal moment per screen |
| Over-reliance on generated code | Subtle perf bugs | Mandatory Instruments pass before merge |

---

## 9. AI Handoff Sheet / Development Handoff

**Ready-to-Copy Prompts for Claude (with UI/UX Pro Max skill installed)**  

**Install / enable UI/UX Pro Max** (pick what matches your toolchain):

- Cursor / project: use the **UI/UX Pro Max** skill package your org vendors (e.g. under `.cursor/skills` / `ui-ux-pro-max`), **or**  
- Marketplace-style install if you use that flow: `/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill`

**Master Prompt Template (use this first):**  
“Using the UI/UX Pro Max skill in shadcn/ui + SwiftUI mode, generate a complete cinematic 3D hero section for [describe screen, e.g., SaaS dashboard onboarding]. Requirements:

- Minimal clean aesthetic with shadcn/ui tokens (neutral palette, subtle shadows, accessible).
- Framer Motion-style spring physics and parallax.
- Full RealityKit integration with RealityView.
- Use Observable Entities, ViewAttachmentComponent for embedded SwiftUI controls, ManipulationComponent for natural gestures, PhysicsBodyComponent + joints for interconnected elements.
- KeyframeAnimator + spring timelines for cinematic entrance.
- Performance optimized (≤100k triangles, LOD, lazy load).
- Include full code + Reality Composer Pro asset notes. Target latest iOS with 120 fps.”

**Component-Specific Prompts:**

- For physics-connected cards: “Generate interconnected 3D dashboard cards using RealityKit physics joints and CustomConnectionSystem.”
- For hero parallax: “Cinematic hero with scroll-driven parallax, environment lighting, and tilt response via device motion.”
- For hybrid controls: “Embed SwiftUI buttons/modals via ViewAttachmentComponent and PresentationComponent on a 3D entity.”

**Review/Optimize Prompt:**  
“Review this RealityKit + SwiftUI code for performance (use WWDC25 best practices). Optimize for latest iPhones while preserving the interconnected game-like feel.”

**Full Scene Prompt:**  
“Build an entire immersive 3D scene in SwiftUI + RealityKit that feels like a high-end $20k Framer website: interconnected elements, real physics, cinematic lighting, shadcn/ui styled attachments.”

**Next Steps After Handoff:**

1. Prototype one hero section using the master prompt.
2. Profile with Instruments.
3. Iterate with UI/UX Pro Max skill for polish.
4. Expand to full app screens.

---

## 10. Scope, Assumptions & Out of Scope

**In scope**

- Design language, motion vocabulary, and immersion levels (L1–L3).  
- Reference implementations: hero, dashboard card cluster, onboarding sequence.  
- Performance budgets, fallbacks, and accessibility requirements.  
- AI prompt library for implementation and review.

**Assumptions**

- Team can ship SwiftUI features on current Xcode + minimum deployment target agreed separately.  
- 3D assets are authored or commissioned; PRD does not mandate a specific art vendor.  
- “WWDC25” framing in the source conversation refers to **then-current** Apple platform direction; update §19 links as APIs evolve.

**Out of scope (v1.0 PRD)**

- Building a full game or open world.  
- Unity/Unreal pipelines (except optional reference for art direction).  
- Backend service design (unless a feature requires live data in-scene — then specify per feature).  
- visionOS-specific shipping requirements (captured as future extension only).

---

## 11. User Journeys & Critical Flows

1. **First open / onboarding:** User sees L2 hero → short motion story → lands in L1 app chrome; Reduce Motion skips physics.  
2. **Dashboard return:** Cached assets; scene resumes or cross-fades; no full reload blocking interaction.  
3. **Deep link into settings or detail:** Target screen opens in L1 if 3D not ready; promotes to L2 when loaded.  
4. **Low power mode / thermal:** System signals → auto-downgrade to L1 or static frame.  
5. **Accessibility:** User enables Reduce Motion → all scenes respect it without losing task completion.

---

## 12. Screen & Component Inventory (Backlog)

Prioritized building blocks (adjust per product):

| Priority | Screen / module | Immersion target | Notes |
|----------|-----------------|------------------|--------|
| P0 | App shell / navigation | L1 | Stable tab bar, sheets, standard focus |
| P0 | Onboarding hero | L2 | First-run only; smallest viable USDZ |
| P1 | Dashboard / home hero | L2 | Scroll-linked parallax |
| P1 | “Connected cards” module | L2–L3 | Physics joints; cap count |
| P2 | Settings / account | L1 | Optional subtle 3D header only |
| P2 | Full scene showcase | L3 | Demo or flagship SKU only |

---

## 13. Design Tokens, Motion & Haptics

- **Tokens:** Map semantic colors, radii, spacing to shadcn-style scales; document SwiftUI `Color` / `CGFloat` sources of truth.  
- **Motion:** Standardize spring presets (response, damping) — align naming with product motion enum (e.g. `reveal`, `snappy`, `bouncy`).  
- **Haptics:** Use `CoreHaptics` or structured UIKit feedback for taps; avoid firing haptics on every physics frame.  
- **Audio:** Spatial audio only where it reinforces the hero; mute-safe; respect silent mode.

---

## 14. Accessibility, Inclusion & Reduced Motion

- **VoiceOver:** Every interactive 3D control exposed via attachment or accessibility proxy; describe state, not mesh topology.  
- **Dynamic Type:** SwiftUI attachments scale; test largest sizes.  
- **Reduce Motion:** Disable parallax, continuous physics, and ambient camera drift; provide static composition.  
- **Color contrast:** 2D chrome must pass WCAG-style contrast in both modes; 3D text uses high-legibility materials.  
- **Motion sickness:** Avoid aggressive camera orbit; offer “stable camera” mode.

---

## 15. Privacy, Security & Data in 3D Context

- **PII in labels:** No user data burned into textures; use runtime SwiftUI attachments for names/avatars.  
- **Camera / LiDAR:** If used, clear purpose string; data minimization; no unexpected recording.  
- **Analytics:** If scene performance is logged, aggregate only; no raw camera frames without consent.

---

## 16. QA, Instrumentation & Acceptance Criteria

**Per milestone**

- [ ] 60 fps min on Tier B; 120 fps where advertised on Tier A.  
- [ ] No frame regressions > 5 ms mean GPU time vs baseline on hero scene.  
- [ ] Cold-start asset load under agreed budget (define ms per product).  
- [ ] Reduce Motion: feature parity for primary tasks.  
- [ ] VoiceOver walkthrough completes primary flow.  
- [ ] Memory: no unbounded growth when navigating in/out of RealityView.

**Tooling:** Xcode Instruments (Time Profiler, GPU, Memory), RealityKit tracing as available, on-device testing weekly.

---

## 17. Phased Delivery Roadmap (Immersion L1 → L3)

| Phase | Deliverable | Exit criteria |
|-------|-------------|----------------|
| **0** | Tokens + motion spec in SwiftUI only | Design sign-off |
| **1** | L1 polish pass on core app | Ship-ready 2D |
| **2** | L2 onboarding + one hero | Instruments green on target devices |
| **3** | L2 dashboard module | User testing / NPS sample |
| **4** | L3 flagship demo (optional) | Poly budget + accessibility signed off |

---

## 18. Open Questions & Decision Log

| ID | Question | Owner | Status |
|----|----------|-------|--------|
| Q1 | Minimum iOS version for required APIs? | Eng | Open |
| Q2 | Single vs multiple RealityViews per screen? | Eng | Open |
| Q3 | Rive vs RealityKit for which modules? | Design + Eng | Open |
| Q4 | A/B test protocol for 2D vs L2 hero? | Product | Open |

*Append rows as decisions land; link to ADRs if your org uses them.*

---

## 19. References & Canonical Apple Sources

- Apple Developer Documentation: **SwiftUI**, **RealityKit**, **RealityView**, **ViewAttachmentComponent**, **ManipulationComponent**, **PhysicsBodyComponent**.  
- WWDC sessions (update yearly): RealityKit + SwiftUI integration, performance, spatial computing.  
- Human Interface Guidelines: motion, accessibility, and comfort.

*Replace with specific session numbers once pinned to a WWDC year the team adopts.*

---

## 20. Appendices

### Appendix A — Triangle & texture budget (starting point)

| Asset class | Guideline |
|-------------|-----------|
| Hero prop (single focal) | ≤ 35k tris |
| Secondary props (instanced) | ≤ 15k tris each |
| Textures (combined) | ≤ 32 MB uncompressed equivalent on GPU; prefer ASTC |
| Materials | Prefer simplified PBR; limit transparent overdraw |

### Appendix B — RealityKit / SwiftUI checklist (pre-ship)

- [ ] LOD or impostor for distant objects  
- [ ] Physics sleep / disable off-screen bodies  
- [ ] Async load with placeholder  
- [ ] Scene teardown on dismiss (no retain cycles)  
- [ ] Fallback when `RealityView` fails to compile content  

### Appendix C — Plugin / skill naming

The source conversation referenced a marketplace slug; your org may vendor the same capability under a different path. **Treat §9 as intent:** “use UI/UX Pro Max + SwiftUI mode,” not a single hard-coded installer.

---

This PRD is the **living** source of truth for RealityMotion on iOS-family platforms. Copy sections into Claude or team docs as needed. For PDF export, print from Markdown or use your usual doc pipeline.

**Prompt for the team:** What is the first screen or component you want to generate from this PRD (onboarding hero, dashboard module, or interconnected cards)?
