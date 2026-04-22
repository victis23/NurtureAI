import Foundation

protocol DiaperLogRepositoryProtocol {
    func fetchAll(for baby: Baby) async throws -> [DiaperLog]
    func fetchRecent(for baby: Baby, limit: Int) async throws -> [DiaperLog]
    func fetchBetween(start: Date, end: Date, for baby: Baby) async throws -> [DiaperLog]
    func fetchLast(for baby: Baby) async throws -> DiaperLog?
    func save(_ log: DiaperLog, for baby: Baby) async throws
    func delete(_ log: DiaperLog) async throws
    func update(_ log: DiaperLog) async throws
}
