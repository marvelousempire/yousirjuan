# 20. Mobile Surfaces - iPhone 17 Series + iPad Pro

## Device Inventory
- 13" iPad Pro: Dedicated kiosk / Sidecar
- iPhone 17 / Pro / Pro Max: Pocket voice interfaces

## Optimizations
- Hybrid STT: SpeechTranscriber + custom WhisperKit (fine-tuned on real estate data)
- Diarization: SpeakerKit with WeSpeaker ResNet34 (local) + ECAPA-TDNN/ResNet293 (DGX)
- Attentive Statistical Pooling implemented in embedding extractors
- Client certificates for Caddy mTLS

## Voice Biometrics Enrollment
Record 15-30s clean audio per user.

## Pockit Integration
Full Swift handler with Neural Engine routing.

**Status**: In Progress