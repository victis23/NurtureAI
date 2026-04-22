import Foundation

protocol AIServiceProtocol {
    func send(
        messages: [ChatMessage],
        stream: Bool
    ) async throws -> AsyncThrowingStream<String, Error>

    func sendBlocking(messages: [ChatMessage]) async throws -> String
}

struct ChatMessage: Codable {
    let role: String
    let content: String

    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: "user", content: content)
    }

    static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: "assistant", content: content)
    }

    static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: "system", content: content)
    }
}
