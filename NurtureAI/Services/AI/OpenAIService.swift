import Foundation

final class OpenAIService: AIServiceProtocol {
    private let model: String
    private let maxTokens: Int
    private let keychain: KeychainHelper

    private var apiKey: String {
        get throws {
            guard let key = keychain.read(service: "NurtureAI", account: "openai-api-key"),
                  !key.isEmpty else {
                throw AIError.missingAPIKey
            }
            return key
        }
    }

    init(
        model: String = "gpt-4o",
        maxTokens: Int = 1024,
        keychain: KeychainHelper = .shared
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.keychain = keychain
    }

    func send(
        messages: [ChatMessage],
        stream: Bool = true
    ) async throws -> AsyncThrowingStream<String, Error> {
        let key = try apiKey
        let body = OpenAIChatRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            stream: stream
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: AIError.invalidResponse)
                        return
                    }
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: AIError.httpError(httpResponse.statusCode))
                        return
                    }

                    if stream {
                        for try await line in bytes.lines {
                            guard line.hasPrefix("data: ") else { continue }
                            let data = String(line.dropFirst(6))
                            if data == "[DONE]" { break }
                            guard let jsonData = data.data(using: .utf8),
                                  let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData),
                                  let text = chunk.choices.first?.delta.content else {
                                continue
                            }
                            continuation.yield(text)
                        }
                        continuation.finish()
                    } else {
                        var fullData = Data()
                        for try await byte in bytes {
                            fullData.append(byte)
                        }
                        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: fullData)
                        let content = decoded.choices.first?.message.content ?? ""
                        continuation.yield(content)
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func sendBlocking(messages: [ChatMessage]) async throws -> String {
        var result = ""
        for try await chunk in try await send(messages: messages, stream: false) {
            result += chunk
        }
        return result
    }
}

// MARK: - Request / Response models

private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, stream
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}

// MARK: - Errors

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case safetyFiltered(String)
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured. Please add your key in Settings."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .httpError(let code):
            return "AI service returned HTTP \(code)."
        case .safetyFiltered(let reason):
            return reason
        case .contextUnavailable:
            return "Baby context is not available."
        }
    }
}
