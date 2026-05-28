import Foundation

/// Returns the SF Symbols name appropriate for a given paradigm label set and UI context.
enum IconKind {
    case day, tasks, world, signOut, voice
}

func icon(for labelSet: String, kind: IconKind) -> String {
    switch labelSet {
    case "executive":
        return executiveIcon(kind)
    case "warm":
        return warmIcon(kind)
    case "technical":
        return technicalIcon(kind)
    case "full":
        return fullIcon(kind)
    case "casual":
        return casualIcon(kind)
    default:
        return defaultIcon(kind)
    }
}

// MARK: - Per-paradigm maps

private func executiveIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "calendar.badge.clock"
    case .tasks:   return "doc.text.fill"
    case .world:   return "building.columns.fill"
    case .signOut: return "rectangle.portrait.and.arrow.forward"
    case .voice:   return "waveform.badge.mic"
    }
}

private func warmIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "sun.horizon.fill"
    case .tasks:   return "checklist.checked"
    case .world:   return "house.fill"
    case .signOut: return "hand.wave.fill"
    case .voice:   return "mic.fill"
    }
}

private func technicalIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "terminal.fill"
    case .tasks:   return "list.bullet.clipboard.fill"
    case .world:   return "server.rack"
    case .signOut: return "poweroff"
    case .voice:   return "waveform"
    }
}

private func fullIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "crown.fill"
    case .tasks:   return "scroll.fill"
    case .world:   return "globe.americas.fill"
    case .signOut: return "arrow.left.square.fill"
    case .voice:   return "mic.badge.plus"
    }
}

private func casualIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "sun.max.fill"
    case .tasks:   return "checkmark.circle.fill"
    case .world:   return "map.fill"
    case .signOut: return "figure.walk.departure"
    case .voice:   return "mic.circle.fill"
    }
}

private func defaultIcon(_ kind: IconKind) -> String {
    switch kind {
    case .day:     return "calendar"
    case .tasks:   return "list.bullet"
    case .world:   return "globe"
    case .signOut: return "rectangle.portrait.and.arrow.forward"
    case .voice:   return "mic"
    }
}
