import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        ZStack {
            // Paradigm-aware backdrop fills the whole window and crossfades on user change.
            Color(hex: session.current?.persona.paradigm.background ?? "#0A0A12")
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: session.current?.userId)

            Group {
                switch session.phase {
                case .auth:
                    AuthView()
                case .home:
                    HomeWorldView()
                case .voice:
                    VoiceView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .animation(.easeInOut(duration: 0.45), value: session.phase)
        }
    }
}

#Preview {
    RootView().environmentObject(SessionStore())
}
