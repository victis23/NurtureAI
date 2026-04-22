import Foundation
import SwiftData

final class SwiftDataConversationRepository: ConversationRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(for baby: Baby) async throws -> [AIConversation] {
        let babyID = baby.id
        let descriptor = FetchDescriptor<AIConversation>(
            predicate: #Predicate { $0.baby?.id == babyID },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(by id: UUID) async throws -> AIConversation? {
        let descriptor = FetchDescriptor<AIConversation>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ conversation: AIConversation, for baby: Baby) async throws {
        conversation.baby = baby
        modelContext.insert(conversation)
        try modelContext.save()
    }

    func addMessage(_ message: AIMessage, to conversation: AIConversation) async throws {
        message.conversation = conversation
        modelContext.insert(message)
        conversation.updatedAt = Date()
        try modelContext.save()
    }

    func delete(_ conversation: AIConversation) async throws {
        modelContext.delete(conversation)
        try modelContext.save()
    }

    func update(_ conversation: AIConversation) async throws {
        conversation.updatedAt = Date()
        try modelContext.save()
    }
}
