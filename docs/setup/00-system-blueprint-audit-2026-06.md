# You-Sir Juan System Blueprint & Audit 2026-06

**Comprehensive Improvement Plan** — Voice, Security, Memory, Devices, and Infrastructure

**Date**: June 2026  
**Branch**: `voice-security-audit-2026-06`

## 1. Executive Summary

You-Sir Juan is a private, self-hosted AI family office platform. This audit addresses key gaps:
- Voice system reliability and features
- Short-term memory (Redis)
- Zero-trust security model
- Device integration (iPhone 17 series + 13" iPad Pro)
- DNS privacy
- WireGuard mesh hardening

**Core Principle**: Everything stays 100% private on our hardware. No Tailscale, Netbird, or any third-party coordination services.

## 2. Security Redesign — Zero-Trust Model

**Current Issue**: WireGuard mesh provides too much implicit trust.

**New Architecture**:
- WireGuard = encrypted transport layer only
- Docker networks: `control-net`, `voice-net`, `data-net`
- **Caddy** as central mTLS auth proxy + "Doors"
- All services bind to localhost / internal networks
- Per-device short-lived client certificates
- Internal domains: `voice.home`, `nephew.home`, `pockit.home`, `dns.home`, etc.

**Caddy Deployment**: See `infrastructure/caddy/`

## 3. Redis Foundation (Short-Term Memory + RAG)

- **HA**: Redis Sentinel (Master + Replica + 3 Sentinels)
- **Persistence**: Hybrid RDB + AOF (`appendfsync everysec`)
- **Vector Search**: SVS-VAMANA index with **LVQ8 / LeanVec8x8** quantization + HNSW tuning guide
- **Integration**: LangGraph (`RedisSaver` + `RedisStore`) + Redis Agent Memory
- **Quantization**: LVQ, LeanVec for memory efficiency

See: `infrastructure/redis-sentinel/`, `docs/setup/21-redis-persistence.md`, `docs/setup/22-hnsw-tuning.md`, `docs/setup/23-lvq-quantization.md`

## 4. Voice System Upgrade (Holler / Parakeet / Pockit)

**Hybrid STT**:
- On-device: Apple `SpeechAnalyzer` + `SpeechTranscriber` (volatile results, timestamps)
- Advanced: Custom WhisperKit (fine-tuned with whisperkittools on real estate/notary data)

**Speaker Diarization & Biometrics**:
- SpeakerKit (Argmax) + WeSpeaker ResNet34 (local on iOS) / ResNet293 or ECAPA-TDNN (DGX)
- Attentive Statistical Pooling implementation
- Voice enrollment (15–30s clean audio → embeddings)

**Optimizations**:
- Apple Neural Engine (A19 Pro on iPhone 17 / iPad Pro)
- Intel OpenVINO + NNCF quantization for future edge nodes

See: `docs/setup/11-voice-parakeet-premium-stack.md`, `docs/setup/24-apple-neural-engine-voice-optimization.md`

## 5. Device Onboarding

- **13" iPad Pro**: Dedicated kiosk + Sidecar secondary monitor
- **iPhone 17 / 17 Pro / 17 Pro Max**: Pocket voice interfaces with local Neural Engine STT + diarization
- One-time client certificate installation via AirDrop / profile

## 6. DNS Privacy Layer

**Self-hosted Unbound + Caddy** exposing:
- DoH: `https://dns.home/dns-query`
- DoT / DoQ: `dns.home:853`

See: `infrastructure/dns/`

## 7. WireGuard Mesh

- Pure self-hosted, no third-party services
- Hub-and-spoke with central hub (VPS or Protectli)
- PersistentKeepalive = 25
- Prefer IPv6 for NAT bypass
- Caddy mTLS provides the real access control

## 8. Implementation Roadmap (Priority Order)

1. Deploy Redis Sentinel + LangGraph integration
2. Deploy Caddy + mTLS Doors + certificates
3. Install client certs on iPad Pro + iPhones
4. Voice pipeline (SpeechTranscriber + SpeakerKit + hybrid routing)
5. DNS privacy stack (Unbound + DoH/DoT/DoQ)
6. Full testing + documentation

## 9. Privacy Mandate (Non-Negotiable)

- All components self-hosted on our hardware
- WireGuard = private transport only
- No external coordination or resolver services
- All traffic stays inside our controlled mesh + Caddy auth

---

**Status**: In Progress — Review, test, and merge when ready.

**Next Immediate Actions**:
- Test Redis Sentinel
- Deploy & configure Caddy
- Roll out device certificates

This blueprint serves as the single source of truth for the current system redesign.
