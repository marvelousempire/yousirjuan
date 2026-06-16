## Major Updates (June 2026)

### Redis Short-Term Memory
- Deploy on DGX `voice-net`
- Semantic caching for voice queries

### Diarization & Speaker ID
- SpeakerKit + WeSpeaker ResNet34 / ECAPA-TDNN
- Attentive Statistical Pooling (see code in appendix)
- Voice biometrics enrollment

### iOS Optimizations
- iPhone 17 A19 Pro Neural Engine
- Hybrid SpeechAnalyzer + WhisperKit

### Security
- All voice traffic through Caddy Doors

## Implementation Priority
1. Redis
2. Caddy
3. Device certs
4. Voice pipeline

(Previous content preserved below...)