import Foundation
import SwiftData

@MainActor
protocol BabyRepositoryProtocol {
    func fetchAll() throws -> [Baby]
    func fetch(id: UUID) throws -> Baby?
    func save(_ baby: Baby) throws
    func delete(_ baby: Baby) throws
    func deleteAll() throws
}

@MainActor
final class BabyRepository: BabyRepositoryProtocol, @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Baby] {
        let descriptor = FetchDescriptor<Baby>(sortBy: [SortDescriptor(\.createdAt)])
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> Baby? {
        let descriptor = FetchDescriptor<Baby>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func save(_ baby: Baby) throws {
        if baby.modelContext == nil {
            context.insert(baby)
        }
        try context.save()
    }

    func delete(_ baby: Baby) throws {
        context.delete(baby)
        try context.save()
    }

    /// Deletes every Baby (and its cascade-deleted BabyLog + AIInsight records).
    /// Used during account deletion to wipe all local data.
    func deleteAll() throws {
        let babies = try fetchAll()
        for baby in babies {
            context.delete(baby)
        }
        try context.save()
    }
}
