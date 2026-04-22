import Foundation
import SwiftData

final class SwiftDataBabyRepository: BabyRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Baby] {
        let descriptor = FetchDescriptor<Baby>(sortBy: [SortDescriptor(\.createdAt)])
        return try modelContext.fetch(descriptor)
    }

    func fetch(by id: UUID) async throws -> Baby? {
        let descriptor = FetchDescriptor<Baby>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ baby: Baby) async throws {
        modelContext.insert(baby)
        try modelContext.save()
    }

    func delete(_ baby: Baby) async throws {
        modelContext.delete(baby)
        try modelContext.save()
    }

    func update(_ baby: Baby) async throws {
        try modelContext.save()
    }
}
