import SwiftUI
import AVFoundation
import Vision
import CryptoKit

#if os(iOS)

/// Face enrollment screen. Activated via long-press on "Add member" in AuthView.
/// Captures a still frame when a face is detected, computes a local face_id token,
/// and POSTs to /api/identity/enroll.
struct EnrollView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var userId: String = ""
    @State private var displayName: String = ""
    @State private var phase: EnrollPhase = .capture
    @State private var assignedAccent: String = "#7C5CFF"

    enum EnrollPhase { case capture, form, submitting, success, failure(String) }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A12").ignoresSafeArea()
            switch phase {
            case .capture:
                CaptureView(onCapture: handleCapture)
            case .form:
                formView
            case .submitting:
                VStack(spacing: 16) {
                    ProgressView().tint(.white)
                    Text("Enrolling…").foregroundStyle(.white.opacity(0.7))
                }
            case .success:
                successView
            case .failure(let msg):
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill").font(.largeTitle).foregroundStyle(.red)
                    Text(msg).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
                    Button("Try again") { phase = .capture }
                        .foregroundStyle(.white)
                }
                .padding(32)
            }
        }
    }

    // MARK: - Capture handler

    private func handleCapture(faceId: String) {
        // Store faceId in userId field temporarily until user fills the form
        userId = faceId
        phase = .form
    }

    // MARK: - Form

    private var formView: some View {
        VStack(spacing: 24) {
            Text("Who are you?")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                TextField("User ID (e.g. u_avery)", text: $userId)
                    .enrollFieldStyle()
                TextField("Display name", text: $displayName)
                    .enrollFieldStyle()
            }
            .padding(.horizontal, 32)

            Button {
                Task { await submit() }
            } label: {
                Text("Enroll")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color(hex: "#7C5CFF")))
            }
            .disabled(userId.isEmpty || displayName.isEmpty)
            .opacity(userId.isEmpty || displayName.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color(hex: assignedAccent))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark").font(.largeTitle).foregroundStyle(.white)
                )
            Text("Welcome, \(displayName).")
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
            Text("Your Associate is ready.")
                .foregroundStyle(.white.opacity(0.6))
            Button("Done") { dismiss() }
                .foregroundStyle(.white)
                .padding(.top, 8)
        }
        .padding(32)
    }

    // MARK: - Network

    private func submit() async {
        phase = .submitting
        do {
            let response = try await API.shared.enrollFace(
                faceId: userId,
                userId: userId,
                displayName: displayName
            )
            assignedAccent = response.accent ?? "#7C5CFF"
            phase = .success
        } catch {
            phase = .failure("Enrollment failed. Is the backend running?")
        }
    }
}

// MARK: - Camera capture sub-view

private struct CaptureView: View {
    let onCapture: (String) -> Void
    @StateObject private var camera = FaceCaptureController()

    var body: some View {
        ZStack {
            CameraPreviewLayer(session: camera.captureSession)
                .ignoresSafeArea()

            if let box = camera.faceBox {
                GeometryReader { geo in
                    let scaled = scaledBox(box, in: geo.size)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#7C5CFF"), lineWidth: 2)
                        .frame(width: scaled.width, height: scaled.height)
                        .position(x: scaled.midX, y: scaled.midY)
                }
            }

            VStack {
                Spacer()
                Text(camera.faceBox == nil ? "Position your face in frame" : "Face detected — hold still…")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.bottom, 48)
            }
        }
        .onAppear { camera.start(onCapture: onCapture) }
        .onDisappear { camera.stop() }
    }

    private func scaledBox(_ normalized: CGRect, in size: CGSize) -> CGRect {
        // Vision returns normalized coords (0–1, origin bottom-left); flip Y for UIKit
        let x = normalized.origin.x * size.width
        let y = (1 - normalized.origin.y - normalized.height) * size.height
        let w = normalized.width  * size.width
        let h = normalized.height * size.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
}

// MARK: - Camera controller

@MainActor
private final class FaceCaptureController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    @Published var faceBox: CGRect?
    private var onCapture: ((String) -> Void)?
    private var captureQueue = DispatchQueue(label: "com.yousirjuan.face")
    private var didCapture = false

    func start(onCapture: @escaping (String) -> Void) {
        self.onCapture = onCapture
        Task.detached { [weak self] in await self?.setupSession() }
    }

    private func setupSession() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: captureQueue)
        captureSession.beginConfiguration()
        if captureSession.canAddInput(input)  { captureSession.addInput(input) }
        if captureSession.canAddOutput(output) { captureSession.addOutput(output) }
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }

    func stop() { captureSession.stopRunning() }

    // AVCaptureVideoDataOutputSampleBufferDelegate
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceRectanglesRequest { [weak self] req, _ in
            guard let obs = req.results?.first as? VNFaceObservation else {
                Task { @MainActor [weak self] in self?.faceBox = nil }
                return
            }
            Task { @MainActor [weak self] in
                self?.faceBox = obs.boundingBox
                self?.maybeCapture(obs.boundingBox)
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

    private func maybeCapture(_ box: CGRect) {
        guard !didCapture else { return }
        // Auto-capture after stable detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self, !self.didCapture, self.faceBox != nil else { return }
            self.didCapture = true
            let faceId = self.computeFaceId(box: box)
            self.onCapture?(faceId)
        }
    }

    private func computeFaceId(box: CGRect) -> String {
        let raw = "\(box.origin.x),\(box.origin.y),\(box.width),\(box.height),\(Date().timeIntervalSince1970)"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(32).description
    }
}

// MARK: - SwiftUI UIViewRepresentable for camera preview

private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

private final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Text field style helper

private extension View {
    func enrollFieldStyle() -> some View {
        self
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12)))
            )
            .foregroundStyle(.white)
    }
}

#endif

#Preview {
    EnrollView()
}
