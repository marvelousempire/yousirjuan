import Foundation

struct Persona: Codable, Equatable {
    let userId: String
    let name: String
    let household: String
    let role: String
    let paradigm: Paradigm
    let agent: Agent
}

struct Paradigm: Codable, Equatable {
    let palette: String
    let accent: String
    let background: String
    let foreground: String
    let layout: String
    let labelSet: String
    let typography: String
    let mood: String
}

struct Agent: Codable, Equatable {
    let name: String
    let voice: String
    let persona: String
    let avatar: String?
    let greeting: String
}

struct SessionData: Codable, Equatable {
    let sessionId: String
    let userId: String
    let persona: Persona
}

struct EnrolledFace: Codable, Identifiable {
    let faceId: String
    let userId: String
    var id: String { faceId }
}
