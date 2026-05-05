import Foundation

struct AIResponse: Codable {
    let causes: [AICause]
    let escalation: AIEscalation
    let reassurance: String
    let confidence: Double
    let followUp: String?
    /// Rolling 1-3 sentence summary the model emits each turn so future
    /// follow-ups can be tailored to the conversation. Optional: off-topic
    /// replies and any pre-existing cached responses simply omit it.
    let historicalContext: String?

    enum CodingKeys: String, CodingKey {
        case causes, escalation, reassurance, confidence
        case followUp = "follow_up"
        case historicalContext = "historical_context"
    }
}

struct AICause: Codable, Identifiable {
    var id: UUID { UUID() }
    let label: String
    let probability: Double
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
