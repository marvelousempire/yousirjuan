import UIKit

/// Wraps Guided Access so the kiosk surface locks the device to the app
/// when unattended and unlocks when a session ends.
final class KioskMode {
    static func enable() {
        UIAccessibility.requestGuidedAccessSession(enabled: true) { _ in }
    }

    static func disable() {
        UIAccessibility.requestGuidedAccessSession(enabled: false) { _ in }
    }
}
