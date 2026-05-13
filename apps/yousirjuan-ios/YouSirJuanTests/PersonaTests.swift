import XCTest
import SwiftUI
@testable import YouSirJuan

final class PersonaTests: XCTestCase {

    // MARK: - Color(hex:)

    func testHexParsesKnownObsidianAccent() {
        let color = Color(hex: "#7C5CFF")
        // Extract components via UIColor for assertion
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, CGFloat(0x7C) / 255, accuracy: 0.01)
        XCTAssertEqual(g, CGFloat(0x5C) / 255, accuracy: 0.01)
        XCTAssertEqual(b, CGFloat(0xFF) / 255, accuracy: 0.01)
        XCTAssertEqual(a, 1.0, accuracy: 0.01)
    }

    func testHexParsesObsidianDarkBackground() {
        let color = Color(hex: "#0A0A12")
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, CGFloat(0x0A) / 255, accuracy: 0.01)
        XCTAssertEqual(g, CGFloat(0x0A) / 255, accuracy: 0.01)
        XCTAssertEqual(b, CGFloat(0x12) / 255, accuracy: 0.01)
    }

    func testHexWithoutHashPrefix() {
        // Should also parse without the leading #
        let withHash = Color(hex: "#FFFFFF")
        let withoutHash = Color(hex: "FFFFFF")
        let ui1 = UIColor(withHash)
        let ui2 = UIColor(withoutHash)
        var r1: CGFloat = 0, r2: CGFloat = 0
        ui1.getRed(&r1, green: nil, blue: nil, alpha: nil)
        ui2.getRed(&r2, green: nil, blue: nil, alpha: nil)
        XCTAssertEqual(r1, r2, accuracy: 0.01)
    }

    func testHexFallbackForInvalidInput() {
        // Invalid hex returns fallback color (#F5F3FF from Color+Hex.swift)
        let color = Color(hex: "ZZZ")
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, CGFloat(0xF5) / 255, accuracy: 0.01)
        XCTAssertEqual(g, CGFloat(0xF3) / 255, accuracy: 0.01)
        XCTAssertEqual(b, CGFloat(0xFF) / 255, accuracy: 0.01)
    }

    // MARK: - Paradigm label set logic

    func testParadigmDecodesFromJSON() throws {
        let json = """
        {
          "palette": "obsidian-violet",
          "accent": "#7C5CFF",
          "background": "#0A0A12",
          "foreground": "#F5F3FF",
          "layout": "executive-grid",
          "labelSet": "executive",
          "typography": "serif-strong",
          "mood": "calm"
        }
        """
        let paradigm = try JSONDecoder().decode(Paradigm.self, from: Data(json.utf8))
        XCTAssertEqual(paradigm.labelSet, "executive")
        XCTAssertEqual(paradigm.accent, "#7C5CFF")
        XCTAssertEqual(paradigm.layout, "executive-grid")
    }

    func testAgentDecodesFromJSON() throws {
        let json = """
        {
          "name": "JUAN",
          "voice": "deep_male_calm",
          "persona": "sovereign",
          "avatar": null,
          "greeting": "Good morning. I have your briefing ready."
        }
        """
        let agent = try JSONDecoder().decode(Agent.self, from: Data(json.utf8))
        XCTAssertEqual(agent.name, "JUAN")
        XCTAssertEqual(agent.voice, "deep_male_calm")
        XCTAssertNil(agent.avatar)
    }

    func testPersonaEquality() throws {
        let json = """
        {
          "userId": "u_avery",
          "name": "Avery Goodman",
          "household": "Goodman",
          "role": "principal",
          "paradigm": {
            "palette": "obsidian-violet",
            "accent": "#7C5CFF",
            "background": "#0A0A12",
            "foreground": "#F5F3FF",
            "layout": "executive-grid",
            "labelSet": "executive",
            "typography": "serif-strong",
            "mood": "calm"
          },
          "agent": {
            "name": "JUAN",
            "voice": "deep_male_calm",
            "persona": "sovereign",
            "avatar": null,
            "greeting": "Good morning."
          }
        }
        """
        let p1 = try JSONDecoder().decode(Persona.self, from: Data(json.utf8))
        let p2 = try JSONDecoder().decode(Persona.self, from: Data(json.utf8))
        XCTAssertEqual(p1, p2)
    }
}
