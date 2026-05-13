import SwiftUI
#if os(iOS)
import AVFoundation
#endif

struct AuthView: View {
    @EnvironmentObject var session: SessionStore
    @State private var faces: [EnrolledFace] = []
    @State private var recognizing: String?
    @State private var error: String?
    @State private var showEnroll = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 12) {
                Text("YOU-SIR JUAN")
                    .font(.caption)
                    .tracking(6)
                    .opacity(0.6)
                    .foregroundStyle(.white)
                Text("Step into your world.")
                    .font(.system(size: 44, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("Your Associate Agent recognizes you on contact.\nFor this preview, choose who you are.")
                    .font(.callout)
                    .opacity(0.7)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 48)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(faces) { face in
                    FaceTile(
                        face: face,
                        recognizing: recognizing == face.faceId,
                        disabled: recognizing != nil
                    ) {
                        Task { await pick(face) }
                    }
                }

                // "Add member" tile — long-press opens face enrollment
                AddMemberTile(showEnroll: $showEnroll)
            }
            .padding(.horizontal, 32)

            if let error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.top, 24)
            }
            Spacer()
        }
        .task { await loadFaces() }
        .sheet(isPresented: $showEnroll) {
            #if os(iOS)
            EnrollView()
            #endif
        }
    }

    private func loadFaces() async {
        do {
            faces = try await API.shared.listFaces()
        } catch {
            self.error = "Could not reach the family registry. Is the backend running?"
        }
    }

    private func pick(_ face: EnrolledFace) async {
        recognizing = face.faceId
        error = nil
        do {
            // Soft delay so the moment feels like recognition, not a button press.
            try? await Task.sleep(nanoseconds: 700_000_000)
            try await session.signIn(faceId: face.faceId)
        } catch {
            self.error = "We could not place you. Try again."
            recognizing = nil
        }
    }
}

private struct FaceTile: View {
    let face: EnrolledFace
    let recognizing: Bool
    let disabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.15)))
                VStack(alignment: .leading, spacing: 6) {
                    Text(face.userId.replacingOccurrences(of: "u_", with: "").uppercased())
                        .font(.caption2)
                        .tracking(2)
                        .opacity(0.5)
                    Text(labelForUser(face.userId))
                        .font(.title2.weight(.semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
                .foregroundStyle(.white)

                if recognizing {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.black.opacity(0.35))
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Recognizing…").font(.caption).foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .frame(height: 130)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled && !recognizing ? 0.5 : 1.0)
        .scaleEffect(recognizing ? 0.98 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: recognizing)
    }

    private func labelForUser(_ id: String) -> String {
        switch id {
        case "u_avery":       return "Avery"
        case "u_bobby":       return "Robert Bobby"
        case "u_nivram":      return "NIVRAM"
        case "u_yousirjuan":  return "Yousir Juan"
        default: return id.replacingOccurrences(of: "u_", with: "").capitalized
        }
    }
}

// MARK: - Add member tile

private struct AddMemberTile: View {
    @Binding var showEnroll: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                        .foregroundStyle(.white.opacity(0.2))
                )
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .opacity(0.4)
                Text("Add member")
                    .font(.caption)
                    .opacity(0.4)
                Text("Hold to enroll")
                    .font(.caption2)
                    .opacity(0.25)
            }
            .foregroundStyle(.white)
        }
        .frame(height: 130)
        .onLongPressGesture(minimumDuration: 0.8) {
            showEnroll = true
        }
    }
}

#Preview {
    AuthView().environmentObject(SessionStore())
        .background(Color(hex: "#0A0A12"))
}
