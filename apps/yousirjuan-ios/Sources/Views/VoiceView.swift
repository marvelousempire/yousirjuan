import SwiftUI
import Speech
import AVFoundation

struct VoiceView: View {
    @EnvironmentObject var session: SessionStore
    @State private var draft: String = ""
    @State private var listening = false
    @State private var recognizer = SpeechRecognizer()

    var body: some View {
        if let s = session.current {
            content(s)
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    private func content(_ s: SessionData) -> some View {
        let persona = s.persona
        let accent = Color(hex: persona.paradigm.accent)
        let fg = Color(hex: persona.paradigm.foreground)

        VStack(spacing: 0) {
            HStack {
                Button(action: { session.goHome() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back").font(.callout)
                    }
                    .foregroundStyle(fg.opacity(0.7))
                }
                Spacer()
                Text("Talking to \(persona.agent.name)")
                    .font(.caption).tracking(2).opacity(0.5)
                Spacer()
                Color.clear.frame(width: 60)
            }
            .padding(.horizontal, 32).padding(.top, 48)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(session.transcript) { turn in
                            TurnBubble(turn: turn, persona: persona)
                                .id(turn.id)
                        }
                    }
                    .padding(.horizontal, 32).padding(.top, 24).padding(.bottom, 8)
                }
                .onChange(of: session.transcript.count) { _, _ in
                    if let last = session.transcript.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Input row
            HStack(spacing: 10) {
                Button {
                    Task { await toggleListening() }
                } label: {
                    Circle()
                        .fill(listening ? accent : Color.white.opacity(0.0))
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(fg.opacity(0.25)))
                        .overlay(
                            Image(systemName: listening
                                  ? icon(for: persona.paradigm.labelSet, kind: .voice)
                                  : "mic")
                                .foregroundStyle(listening ? .white : fg)
                        )
                        .scaleEffect(listening ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: listening)
                }
                .buttonStyle(.plain)

                TextField("Or type…", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Capsule().fill(.white.opacity(0.05)).overlay(Capsule().stroke(fg.opacity(0.1))))
                    .onSubmit { send() }
                    .foregroundStyle(fg)

                Button("Send") { send() }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Capsule().fill(accent))
                    .foregroundStyle(.white)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 32).padding(.bottom, 32)
        }
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await session.sendUtterance(text) }
    }

    private func toggleListening() async {
        if listening {
            recognizer.stop()
            listening = false
            if !recognizer.lastTranscript.isEmpty {
                draft = recognizer.lastTranscript
                send()
            }
        } else {
            do {
                try await recognizer.start()
                listening = true
            } catch {
                // Permission denied or unavailable — typing still works.
            }
        }
    }
}

private struct TurnBubble: View {
    let turn: TranscriptTurn
    let persona: Persona

    var body: some View {
        let isUser = turn.role == .user
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(isUser ? persona.name : persona.agent.name)
                    .font(.caption2).tracking(1.5).opacity(0.5)
                Text(turn.text)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isUser
                                  ? Color(hex: persona.paradigm.accent).opacity(0.25)
                                  : Color.white.opacity(0.06))
                    )
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}

@MainActor
final class SpeechRecognizer {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    var lastTranscript: String = ""

    func start() async throws {
        lastTranscript = ""
        let status = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard status == .authorized else { throw NSError(domain: "speech", code: 1) }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let fmt = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, _ in
            if let r = result {
                self?.lastTranscript = r.bestTranscription.formattedString
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }
}
