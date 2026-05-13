import SwiftUI
import RealityKit

struct HomeWorldView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        if let s = session.current {
            content(s)
        } else {
            ProgressView().onAppear { session.signOut() }
        }
    }

    @ViewBuilder
    private func content(_ s: SessionData) -> some View {
        let persona = s.persona
        let labels = labelSet(for: persona.paradigm.labelSet)
        let fg = Color(hex: persona.paradigm.foreground)
        let accent = Color(hex: persona.paradigm.accent)
        let labelSetKey = persona.paradigm.labelSet

        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(persona.household.uppercased())
                        .font(.caption)
                        .tracking(4)
                        .opacity(0.5)
                    Text("Hello, \(persona.name).")
                        .font(typographyFor(persona.paradigm.typography))
                        .foregroundStyle(fg)
                }
                Spacer()
                Button {
                    session.signOut()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: labelSetKey, kind: .signOut))
                        Text(labels.signOut)
                    }
                }
                .font(.callout)
                .foregroundStyle(fg.opacity(0.7))
            }
            .padding(.horizontal, 32)
            .padding(.top, 48)

            // Associate presence — RealityKit L2 avatar scene
            AvatarRealityView(
                accentHex: persona.paradigm.accent,
                greeting: persona.agent.greeting
            )
            .padding(.horizontal, 32)
            .padding(.top, 24)

            // Tiles
            tileLayout(persona: persona, labels: labels, fg: fg, labelSetKey: labelSetKey)
                .padding(.horizontal, 32)
                .padding(.top, 24)

            Spacer()

            // Voice CTA
            Button { session.openVoice() } label: {
                HStack(spacing: 10) {
                    Image(systemName: icon(for: labelSetKey, kind: .voice))
                    Text("Talk to your Associate")
                        .font(.title3.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Capsule().fill(accent))
            }
            .padding(.bottom, 40)
        }
        .foregroundStyle(fg)
    }

    @ViewBuilder
    private func tileLayout(persona: Persona, labels: LabelSet, fg: Color, labelSetKey: String) -> some View {
        let tiles: [(String, String, String)] = [
            (labels.day,   icon(for: labelSetKey, kind: .day),   "Calm. Nothing demanding."),
            (labels.tasks, icon(for: labelSetKey, kind: .tasks), "Your Associate is keeping the list."),
            (labels.world, icon(for: labelSetKey, kind: .world), "All household systems online."),
        ]

        switch persona.paradigm.layout {
        case "soft-stack":
            VStack(spacing: 12) {
                ForEach(tiles, id: \.0) { Tile(title: $0.0, systemImage: $0.1, caption: $0.2, fg: fg) }
            }
        case "playful-cards":
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tiles, id: \.0) { Tile(title: $0.0, systemImage: $0.1, caption: $0.2, fg: fg) }
            }
        default: // executive-grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tiles, id: \.0) { Tile(title: $0.0, systemImage: $0.1, caption: $0.2, fg: fg) }
            }
        }
    }

    private func typographyFor(_ token: String) -> Font {
        switch token {
        case "serif-strong":     return .system(size: 40, weight: .semibold, design: .serif)
        case "humanist-rounded": return .system(size: 38, weight: .medium,   design: .rounded)
        case "geometric-bold":   return .system(size: 38, weight: .bold,     design: .default)
        default:                 return .system(size: 38, weight: .semibold)
        }
    }
}

private struct Tile: View {
    let title: String
    let systemImage: String
    let caption: String
    let fg: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .opacity(0.7)
                Text(title.uppercased())
                    .font(.caption)
                    .tracking(2)
                    .opacity(0.6)
            }
            Text(caption)
                .font(.callout)
                .opacity(0.9)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(fg.opacity(0.1)))
        )
    }
}

private struct LabelSet {
    let day: String
    let tasks: String
    let world: String
    let signOut: String
}

private func labelSet(for token: String) -> LabelSet {
    switch token {
    case "warm":
        return LabelSet(day: "Your day", tasks: "On your list", world: "Home", signOut: "See you later")
    case "casual":
        return LabelSet(day: "Right now", tasks: "Stuff to do", world: "World", signOut: "Peace out")
    default:
        return LabelSet(day: "Today", tasks: "Briefings", world: "Operations", signOut: "End session")
    }
}
