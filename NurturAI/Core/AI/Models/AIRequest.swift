import Foundation

struct AIRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool
    let responseFormat: ResponseFormat

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case responseFormat = "response_format"
    }
}

// Server-Sent Events chunk from the streaming API
struct StreamChunk: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }
}
