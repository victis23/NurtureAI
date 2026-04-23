import Foundation
import SwiftData

@MainActor
protocol InsightRepositoryProtocol {
    func save(_ insight: AIInsight) throws
    func fetchAll(for baby: Baby) throws -> [AIInsight]
    func updateFeedback(_ insight: AIInsight, wasHelpful: Bool) throws
    func delete(_ insight: AIInsight) throws
}

@MainActor
final class InsightRepository: InsightRepositoryProtocol, @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ insight: AIInsight) throws {
        context.insert(insight)
        try context.save()
    }

    func fetchAll(for baby: Baby) throws -> [AIInsight] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<AIInsight>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func updateFeedback(_ insight: AIInsight, wasHelpful: Bool) throws {
        insight.wasHelpful = wasHelpful
        try context.save()
    }

    func delete(_ insight: AIInsight) throws {
        context.delete(insight)
        try context.save()
    }
}
