import Foundation
import FirebaseFunctions

protocol AIOrchestrating {
    func ask(query: String, context: BabyContext) async throws -> String
}

final class AIOrchestrator: AIOrchestrating {

    private let functions = Functions.functions()

    init() {}

    func ask(query: String, context: BabyContext) async throws -> String {
        let payload: [String: Any] = [
            "query": query,
            "systemPrompt": context.buildSystemPrompt(),
        ]

        let result = try await functions.httpsCallable("askAI").call(payload)

        guard let data = result.data as? [String: Any],
              let responseJSON = data["responseJSON"] as? String
        else {
            throw AIError.invalidResponse
        }

        return responseJSON
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
