import Foundation

struct AIResponse: Codable {
    let causes: [AICause]
    let escalation: AIEscalation
    let reassurance: String
    let confidence: Int
    let followUp: String?

    enum CodingKeys: String, CodingKey {
        case causes, escalation, reassurance, confidence
        case followUp = "follow_up"
    }
}

struct AICause: Codable, Identifiable {
    var id: UUID { UUID() }
    let label: String
    let probability: Int
    let reasoning: String
    let actions: [String]
}

struct AIEscalation: Codable {
    let er: [String]
    let callDoctor: [String]
    let monitor: [String]

    enum CodingKeys: String, CodingKey {
        case er
        case callDoctor = "call_doctor"
        case monitor
    }
}
