import Foundation
import LocalAuthentication

@MainActor
final class SessionStore: ObservableObject {
    enum Phase: Equatable { case auth, home, voice }

    @Published var current: SessionData?
    @Published var phase: Phase = .auth
    @Published var transcript: [TranscriptTurn] = []

    func signIn(faceId: String) async throws {
        // Biometric gate before the network round-trip.
        try await biometricGate()
        let data = try await API.shared.startSession(faceId: faceId)
        self.current = data
        self.phase = .home
    }

    func signOut() {
        self.current = nil
        self.transcript = []
        self.phase = .auth
    }

    func openVoice() { phase = .voice }
    func goHome() { phase = .home }

    func sendUtterance(_ text: String) async {
        guard let userId = current?.userId, !text.isEmpty else { return }
        let userTurn = TranscriptTurn(role: .user, text: text, id: UUID())
        transcript.append(userTurn)
        do {
            let r = try await API.shared.voiceTurn(userId: userId, utterance: text)
            transcript.append(TranscriptTurn(role: .agent, text: r.reply, id: UUID()))
            Speech.shared.speak(r.reply, voiceHint: r.agent.voice)
        } catch {
            transcript.append(TranscriptTurn(role: .agent, text: "I couldn't reach the runtime. Check the API.", id: UUID()))
        }
    }

    private func biometricGate() async throws {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            // Simulator or no biometrics — skip silently for MVP.
            return
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Confirm it's you") { ok, err in
                if ok { cont.resume() } else { cont.resume(throwing: err ?? APIError.badResponse(0)) }
            }
        }
    }
}

struct TranscriptTurn: Identifiable, Equatable {
    enum Role { case user, agent }
    let role: Role
    let text: String
    let id: UUID
}
