import Foundation
import SwiftData

final class SwiftDataGrowthRepository: GrowthRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(for baby: Baby) async throws -> [GrowthMeasurement] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<GrowthMeasurement>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchLatest(for baby: Baby) async throws -> GrowthMeasurement? {
        let babyID = baby.id
        var descriptor = FetchDescriptor<GrowthMeasurement>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func save(_ measurement: GrowthMeasurement, for baby: Baby) async throws {
        measurement.baby = baby
        modelContext.insert(measurement)
        try modelContext.save()
    }

    func delete(_ measurement: GrowthMeasurement) async throws {
        modelContext.delete(measurement)
        try modelContext.save()
    }

    func update(_ measurement: GrowthMeasurement) async throws {
        try modelContext.save()
    }
}
