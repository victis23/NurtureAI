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
        return try JSONDecoder().decode(AIResponse.self, from: data)
    }
}
