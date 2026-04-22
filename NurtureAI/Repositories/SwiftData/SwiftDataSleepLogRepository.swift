import Foundation
import SwiftData

final class SwiftDataSleepLogRepository: SleepLogRepositoryProtocol {
    private let modelContext: ModelContext
    private var contextBuilder: BabyContextBuilder?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func injectContextBuilder(_ builder: BabyContextBuilder) {
        self.contextBuilder = builder
    }

    func fetchAll(for baby: Baby) async throws -> [SleepLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<SleepLog>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecent(for baby: Baby, limit: Int = 20) async throws -> [SleepLog] {
        let babyID = baby.id
        var descriptor = FetchDescriptor<SleepLog>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [SleepLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<SleepLog>(
            predicate: #Predicate {
                $0.baby?.id == babyID && $0.startTime >= start && $0.startTime <= end
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchLast(for baby: Baby) async throws -> SleepLog? {
        return try await fetchRecent(for: baby, limit: 1).first
    }

    func fetchOngoing(for baby: Baby) async throws -> SleepLog? {
        let babyID = baby.id
        let descriptor = FetchDescriptor<SleepLog>(
            predicate: #Predicate { $0.baby?.id == babyID && $0.endTime == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ log: SleepLog, for baby: Baby) async throws {
        log.baby = baby
        modelContext.insert(log)
        try modelContext.save()
        contextBuilder?.invalidate(for: baby)
    }

    func delete(_ log: SleepLog) async throws {
        let baby = log.baby
        modelContext.delete(log)
        try modelContext.save()
        if let baby { contextBuilder?.invalidate(for: baby) }
    }

    func update(_ log: SleepLog) async throws {
        let baby = log.baby
        try modelContext.save()
        if let baby { contextBuilder?.invalidate(for: baby) }
    }
}
