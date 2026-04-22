import Foundation

protocol BabyRepositoryProtocol {
    func fetchAll() async throws -> [Baby]
    func fetch(by id: UUID) async throws -> Baby?
    func save(_ baby: Baby) async throws
    func delete(_ baby: Baby) async throws
    func update(_ baby: Baby) async throws
}
