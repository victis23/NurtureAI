import Foundation
@testable import NurturAI

final class MockFeedingLogRepository: FeedingLogRepositoryProtocol {
    var savedLogs: [FeedingLog] = []
    var shouldThrow = false

    func fetchAll(for baby: Baby) async throws -> [FeedingLog] {
        if shouldThrow { throw TestError.intentional }
        return savedLogs
    }

    func fetchRecent(for baby: Baby, limit: Int) async throws -> [FeedingLog] {
        if shouldThrow { throw TestError.intentional }
        return Array(savedLogs.prefix(limit))
    }

    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [FeedingLog] {
        savedLogs.filter { $0.startTime >= start && $0.startTime <= end }
    }

    func fetchLast(for baby: Baby) async throws -> FeedingLog? {
        savedLogs.first
    }

    func save(_ log: FeedingLog, for baby: Baby) async throws {
        if shouldThrow { throw TestError.intentional }
        savedLogs.append(log)
    }

    func delete(_ log: FeedingLog) async throws {
        savedLogs.removeAll { $0.id == log.id }
    }

    func update(_ log: FeedingLog) async throws {}
}

enum TestError: Error {
    case intentional
}
