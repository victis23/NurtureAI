import Foundation
import SwiftData

@MainActor
protocol LogRepositoryProtocol {
    func fetchLogs(for baby: Baby, since: Date) throws -> [BabyLog]
    func fetchLatest(type: LogType, for baby: Baby) throws -> BabyLog?
    func save(_ log: BabyLog) throws
    func markSynced(_ logs: [BabyLog]) throws
    func fetchUnsynced(for baby: Baby) throws -> [BabyLog]
    func delete(_ log: BabyLog) throws
}

@MainActor
final class LogRepository: LogRepositoryProtocol, @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchLogs(for baby: Baby, since: Date) throws -> [BabyLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<BabyLog>(
            predicate: #Predicate { log in
                log.baby?.id == babyID && log.timestamp >= since
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchLatest(type: LogType, for baby: Baby) throws -> BabyLog? {
        let babyID = baby.id
        let rawType = type.rawValue
        var descriptor = FetchDescriptor<BabyLog>(
            predicate: #Predicate { log in
                log.baby?.id == babyID && log.type.rawValue == rawType
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func save(_ log: BabyLog) throws {
        context.insert(log)
        try context.save()
    }

    func markSynced(_ logs: [BabyLog]) throws {
        for log in logs {
            log.syncedToCloud = true
        }
        try context.save()
    }

    func fetchUnsynced(for baby: Baby) throws -> [BabyLog] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<BabyLog>(
            predicate: #Predicate { log in
                log.baby?.id == babyID && !log.syncedToCloud
            }
        )
        return try context.fetch(descriptor)
    }

    func delete(_ log: BabyLog) throws {
        context.delete(log)
        try context.save()
    }
}
