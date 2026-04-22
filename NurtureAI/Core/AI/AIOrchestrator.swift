import Foundation

protocol AIOrchestrating {
    func stream(query: String, context: BabyContext) -> AsyncThrowingStream<String, Error>
}

final class AIOrchestrator: AIOrchestrating {

    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func stream(query: String, context: BabyContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 30

                    let payload = AIRequest(
                        model: model,
                        messages: [
                            AIRequest.Message(role: "system", content: context.buildSystemPrompt()),
                            AIRequest.Message(role: "user",   content: query)
                        ],
                        temperature: 0.3,
                        stream: true,
                        responseFormat: AIRequest.ResponseFormat(type: "json_object")
                    )
                    request.httpBody = try JSONEncoder().encode(payload)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw AIError.invalidResponse
                    }
                    guard http.statusCode == 200 else {
                        throw AIError.httpError(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: "),
                              line != "data: [DONE]" else { continue }
                        let jsonData = Data(line.dropFirst(6).utf8)
                        guard let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData),
                              let token = chunk.choices.first?.delta.content
                        else { continue }
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

enum AIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case parseError
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The AI service returned an unexpected response."
        case .httpError(let code):
            return "The AI service returned an error (HTTP \(code))."
        case .parseError:
            return "Could not understand the AI response. Please try again."
        case .contextUnavailable:
            return "Baby context could not be loaded. Please try again."
        }
    }
}
