import Foundation
import SwiftData

final class SwiftDataDiaperLogRepository: DiaperLogRepositoryProtocol {
    private let modelContext: ModelContext
    private var contextBuilder: BabyContextBuilder?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func injectContextBuilder(_ builder: BabyContextBuilder) {
        self.contextBuilder = builder
    }

    func fetchAll(for baby: Baby) async throws -> [DiaperLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<DiaperLog>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecent(for baby: Baby, limit: Int = 20) async throws -> [DiaperLog] {
        let babyID = baby.id
        var descriptor = FetchDescriptor<DiaperLog>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [DiaperLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<DiaperLog>(
            predicate: #Predicate {
                $0.baby?.id == babyID && $0.timestamp >= start && $0.timestamp <= end
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchLast(for baby: Baby) async throws -> DiaperLog? {
        return try await fetchRecent(for: baby, limit: 1).first
    }

    func save(_ log: DiaperLog, for baby: Baby) async throws {
        log.baby = baby
        modelContext.insert(log)
        try modelContext.save()
        contextBuilder?.invalidate(for: baby)
    }

    func delete(_ log: DiaperLog) async throws {
        let baby = log.baby
        modelContext.delete(log)
        try modelContext.save()
        if let baby { contextBuilder?.invalidate(for: baby) }
    }

    func update(_ log: DiaperLog) async throws {
        let baby = log.baby
        try modelContext.save()
        if let baby { contextBuilder?.invalidate(for: baby) }
    }
}
