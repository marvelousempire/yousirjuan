import Foundation
import AVFoundation

/// On-device TTS bridge. Phase 2 will swap AVSpeechSynthesizer for the locally-hosted
/// TTS engine (Kokoro/Coqui) routed through the Mac mini runtime so the associate's
/// chosen voice is honored verbatim.
final class Speech {
    static let shared = Speech()
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, voiceHint: String) {
        let u = AVSpeechUtterance(string: text)
        let config = VoiceConfig.make(hint: voiceHint)
        u.rate = AVSpeechUtteranceDefaultSpeechRate * config.rateMultiplier
        u.pitchMultiplier = config.pitch
        u.voice = config.voice
        synth.stopSpeaking(at: .immediate)
        synth.speak(u)
    }
}

// MARK: - Voice configuration

private struct VoiceConfig {
    let voice: AVSpeechSynthesisVoice?
    let pitch: Float
    let rateMultiplier: Float

    static func make(hint: String) -> VoiceConfig {
        switch hint {
        case "deep_male_calm":
            return VoiceConfig(
                voice: preferred(["com.apple.voice.premium.en-US.Evan",
                                  "com.apple.voice.enhanced.en-GB.Daniel"],
                                 fallback: "en-GB"),
                pitch: 0.85, rateMultiplier: 1.0
            )
        case "warm_male_friendly":
            return VoiceConfig(
                voice: preferred(["com.apple.voice.premium.en-US.Aaron"],
                                 fallback: "en-US"),
                pitch: 1.0, rateMultiplier: 1.0
            )
        case "precise_neutral_tech":
            return VoiceConfig(
                voice: preferred(["com.apple.voice.premium.en-US.Samantha"],
                                 fallback: "en-US"),
                pitch: 0.95, rateMultiplier: 1.1
            )
        case "resonant_authority":
            return VoiceConfig(
                voice: preferred(["com.apple.voice.premium.en-US.Tom"],
                                 fallback: "en-US"),
                pitch: 0.8, rateMultiplier: 0.92
            )
        default:
            return VoiceConfig(
                voice: AVSpeechSynthesisVoice(language: "en-US"),
                pitch: 1.0, rateMultiplier: 1.0
            )
        }
    }

    private static func preferred(_ identifiers: [String], fallback lang: String) -> AVSpeechSynthesisVoice? {
        for id in identifiers {
            if let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        }
        return AVSpeechSynthesisVoice(language: lang)
    }
}
