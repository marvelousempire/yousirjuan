import SwiftUI
import RealityKit

#if os(iOS) || os(visionOS)

/// A RealityKit L2 scene that renders the associate "presence" as a floating,
/// pulsing sphere with per-paradigm accent color. Works on both iOS and visionOS.
struct AvatarRealityView: View {
    let accentHex: String
    let greeting: String

    var body: some View {
        ZStack(alignment: .bottom) {
            RealityView { content in
                let sphere = buildSphere(accentHex: accentHex)
                content.add(sphere)
                let light = buildLight(accentHex: accentHex)
                content.add(light)
            }
            .frame(height: 220)

            greetingOverlay
                .padding(.bottom, 8)
        }
        .frame(height: 260)
    }

    private var greetingOverlay: some View {
        Text(greeting)
            .font(.callout)
            .foregroundStyle(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(.black.opacity(0.35))
            )
    }
}

// MARK: - Entity builders

private func buildSphere(accentHex: String) -> Entity {
    let radius: Float = 0.08
    let mesh = MeshResource.generateSphere(radius: radius)
    var material = SimpleMaterial()
    material.color = .init(tint: uiColorFromHex(accentHex).withAlphaComponent(0.92))
    material.roughness = 0.3
    material.metallic = 0.6

    let sphere = ModelEntity(mesh: mesh, materials: [material])
    sphere.position = [0, 0, 0]

    // Physics body — static so it floats without gravity
    sphere.components.set(PhysicsBodyComponent(
        massProperties: .default,
        material: nil,
        mode: .static
    ))

    // Pulsing scale animation using Transform keyframes
    let noRot = simd_quatf(angle: 0, axis: [0, 1, 0])
    let small: Float = 0.94
    let large: Float = 1.06
    let from = Transform(scale: .init(repeating: small), rotation: noRot, translation: [0, 0, 0])
    let to   = Transform(scale: .init(repeating: large), rotation: noRot, translation: [0, 0, 0])

    let anim = FromToByAnimation<Transform>(
        from: from,
        to: to,
        duration: 2.0,
        timing: .easeInOut,
        isAdditive: false,
        bindTarget: .transform,
        repeatMode: .autoReverse
    )

    if let resource = try? AnimationResource.generate(with: anim) {
        sphere.playAnimation(resource.repeat())
    }

    return sphere
}

private func buildLight(accentHex: String) -> Entity {
    let light = Entity()
    light.position = [0, 0.25, 0.1]
    var pointLight = PointLightComponent()
    pointLight.color = uiColorFromHex(accentHex)
    pointLight.intensity = 800
    pointLight.attenuationRadius = 1.5
    light.components.set(pointLight)
    return light
}

private func uiColorFromHex(_ hex: String) -> UIColor {
    let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var int: UInt64 = 0
    Scanner(string: s).scanHexInt64(&int)
    guard s.count == 6 else { return .white }
    let r = CGFloat((int >> 16) & 0xFF) / 255
    let g = CGFloat((int >> 8)  & 0xFF) / 255
    let b = CGFloat(int         & 0xFF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: 1)
}

#endif

#Preview {
    AvatarRealityView(accentHex: "#7C5CFF", greeting: "Good morning. Your briefing is ready.")
        .background(Color(hex: "#0A0A12"))
}
