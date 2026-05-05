import Foundation

struct AIResponseParser {

    func parse(_ raw: String) throws -> AIResponse {
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.parseError
        }
        let decoded = try JSONDecoder().decode(AIResponse.self, from: data)
        return Self.normalizingScales(decoded)
    }

    /// Defensive guard against the model occasionally returning probabilities /
    /// confidence on a 0–1 scale (e.g. `0.65`) instead of the 0–100 integer
    /// scale the UI expects. Anything in `(0, 1]` is rescaled by 100. Values
    /// of exactly 0 are passed through (off-topic responses use 0 confidence
    /// to signal "not a baby-care question").
    private static func normalizingScales(_ response: AIResponse) -> AIResponse {
        func rescale(_ value: Double) -> Double {
            (value > 0 && value <= 1) ? value * 100 : value
        }

        let normalizedCauses = response.causes.map {
            AICause(
                label: $0.label,
                probability: rescale($0.probability),
                reasoning: $0.reasoning,
                actions: $0.actions
            )
        }

        return AIResponse(
            causes: normalizedCauses,
            escalation: response.escalation,
            reassurance: response.reassurance,
            confidence: rescale(response.confidence),
            followUp: response.followUp,
            historicalContext: response.historicalContext
        )
    }
}
