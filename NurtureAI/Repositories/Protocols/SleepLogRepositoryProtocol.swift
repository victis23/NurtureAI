import Foundation

protocol SleepLogRepositoryProtocol {
    func fetchAll(for baby: Baby) async throws -> [SleepLog]
    func fetchRecent(for baby: Baby, limit: Int) async throws -> [SleepLog]
    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [SleepLog]
    func fetchLast(for baby: Baby) async throws -> SleepLog?
    func fetchOngoing(for baby: Baby) async throws -> SleepLog?
    func save(_ log: SleepLog, for baby: Baby) async throws
    func delete(_ log: SleepLog) async throws
    func update(_ log: SleepLog) async throws
}
