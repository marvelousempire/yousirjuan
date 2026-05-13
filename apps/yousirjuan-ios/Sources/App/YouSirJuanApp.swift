import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct YouSirJuanApp: App {
    @StateObject private var session = SessionStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            #if os(visionOS)
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
            #else
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhase(newPhase)
                }
                .onChange(of: session.phase) { _, newPhase in
                    if newPhase == .auth { KioskMode.disable() }
                }
            #endif
        }
        #if os(visionOS)
        ImmersiveSpace(id: "AvatarSpace") {
            AvatarRealityView(accentHex: "#7C5CFF", greeting: "Welcome to your world.")
        }
        #endif
    }

    #if os(iOS)
    private func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active,
              session.current == nil,
              UIDevice.current.userInterfaceIdiom == .pad else { return }
        KioskMode.enable()
    }
    #endif
}
