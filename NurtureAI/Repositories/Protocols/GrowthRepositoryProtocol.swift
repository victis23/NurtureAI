import Foundation

protocol GrowthRepositoryProtocol {
    func fetchAll(for baby: Baby) async throws -> [GrowthMeasurement]
    func fetchLatest(for baby: Baby) async throws -> GrowthMeasurement?
    func save(_ measurement: GrowthMeasurement, for baby: Baby) async throws
    func delete(_ measurement: GrowthMeasurement) async throws
    func update(_ measurement: GrowthMeasurement) async throws
}
