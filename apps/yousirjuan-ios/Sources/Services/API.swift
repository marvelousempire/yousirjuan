import Foundation

enum APIError: Error {
    case badResponse(Int)
    case transport(Error)
}

final class API {
    static let shared = API()

    var baseURL: URL = {
        if let s = ProcessInfo.processInfo.environment["YOUSIRJUAN_API_URL"], let u = URL(string: s) {
            return u
        }
        return URL(string: "http://localhost:4001")!
    }()

    func listFaces() async throws -> [EnrolledFace] {
        struct Body: Decodable { let enrolled: [EnrolledFace] }
        return try await get("/api/identity/faces", as: Body.self).enrolled
    }

    func startSession(faceId: String) async throws -> SessionData {
        try await post("/api/session", body: ["faceId": faceId], as: SessionData.self)
    }

    func voiceTurn(userId: String, utterance: String) async throws -> VoiceTurnResponse {
        try await post("/api/voice/turn", body: ["userId": userId, "utterance": utterance], as: VoiceTurnResponse.self)
    }

    func enrollFace(faceId: String, userId: String, displayName: String) async throws -> EnrollResponse {
        try await post(
            "/api/identity/enroll",
            body: ["faceId": faceId, "userId": userId, "displayName": displayName],
            as: EnrollResponse.self
        )
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ path: String, as: T.Type) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "GET"
        return try await send(req)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any], as: T.Type) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw APIError.badResponse(code)
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }
}

struct VoiceTurnResponse: Decodable {
    let reply: String
    let agent: Agent
}

struct EnrollResponse: Decodable {
    let faceId: String
    let userId: String
    let accent: String?
}
