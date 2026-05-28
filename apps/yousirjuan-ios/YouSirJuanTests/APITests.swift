import XCTest
@testable import YouSirJuan

final class APITests: XCTestCase {

    // MARK: - baseURL

    func testBaseURLDefaultsToLocalhost4001() {
        // When no env var is set the default must resolve to localhost:4001
        let url = API.shared.baseURL
        XCTAssertEqual(url.host, "localhost")
        XCTAssertEqual(url.port, 4001)
        XCTAssertEqual(url.scheme, "http")
    }

    func testBaseURLParsesValidString() {
        // Construct an API-like object to verify URL parsing logic.
        let raw = "https://api.yousirjuan.internal:8080"
        let parsed = URL(string: raw)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.scheme, "https")
        XCTAssertEqual(parsed?.host, "api.yousirjuan.internal")
        XCTAssertEqual(parsed?.port, 8080)
    }

    func testBaseURLRejectsEmptyString() {
        let parsed = URL(string: "")
        // URL(string:"") is non-nil but has no host — we'd fall back to default.
        XCTAssertNil(parsed?.host)
    }

    // MARK: - URL path composition

    func testPathAppendDoesNotDoubleSlash() {
        let base = URL(string: "http://localhost:4001")!
        let full = base.appendingPathComponent("/api/session")
        // appendingPathComponent normalises the slash
        XCTAssertTrue(full.absoluteString.contains("/api/session"))
        XCTAssertFalse(full.absoluteString.contains("//api"))
    }

    // MARK: - VoiceTurnResponse decoding

    func testVoiceTurnResponseDecodesReply() throws {
        let json = """
        {
          "reply": "Good morning, Avery.",
          "agent": {
            "name": "JUAN",
            "voice": "deep_male_calm",
            "persona": "family-office",
            "avatar": null,
            "greeting": "Good morning."
          }
        }
        """
        let response = try JSONDecoder().decode(VoiceTurnResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.reply, "Good morning, Avery.")
        XCTAssertEqual(response.agent.name, "JUAN")
        XCTAssertEqual(response.agent.voice, "deep_male_calm")
    }

    func testEnrolledFaceID() {
        let face = EnrolledFace(faceId: "abc123", userId: "u_avery")
        XCTAssertEqual(face.id, "abc123")
        XCTAssertEqual(face.userId, "u_avery")
    }
}
