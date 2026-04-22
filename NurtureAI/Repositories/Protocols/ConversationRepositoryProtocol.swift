import Foundation

protocol ConversationRepositoryProtocol {
    func fetchAll(for baby: Baby) async throws -> [AIConversation]
    func fetch(by id: UUID) async throws -> AIConversation?
    func save(_ conversation: AIConversation, for baby: Baby) async throws
    func addMessage(_ message: AIMessage, to conversation: AIConversation) async throws
    func delete(_ conversation: AIConversation) async throws
    func update(_ conversation: AIConversation) async throws
}
