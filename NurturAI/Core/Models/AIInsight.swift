import Foundation
import SwiftData

@Model
final class AIInsight {
    var id: UUID
    var createdAt: Date
    var query: String
    var responseJSON: String
    var wasHelpful: Bool?
    var baby: Baby?

    var response: AIResponse? {
        guard let data = responseJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AIResponse.self, from: data)
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        query: String,
        responseJSON: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.query = query
        self.responseJSON = responseJSON
    }
}
