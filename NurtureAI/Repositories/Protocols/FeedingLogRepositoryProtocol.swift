import Foundation

protocol FeedingLogRepositoryProtocol {
    func fetchAll(for baby: Baby) async throws -> [FeedingLog]
    func fetchRecent(for baby: Baby, limit: Int) async throws -> [FeedingLog]
    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [FeedingLog]
    func fetchLast(for baby: Baby) async throws -> FeedingLog?
    func save(_ log: FeedingLog, for baby: Baby) async throws
    func delete(_ log: FeedingLog) async throws
    func update(_ log: FeedingLog) async throws
}
