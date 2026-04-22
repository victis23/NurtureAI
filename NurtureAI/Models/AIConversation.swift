import Foundation
import SwiftData

@Model
final class AIConversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var messages: [AIMessage]
    @Relationship(inverse: \Baby.conversations) var baby: Baby?

    init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.messages = []
    }
}

@Model
final class AIMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var isSafetyFiltered: Bool

    @Relationship(inverse: \AIConversation.messages) var conversation: AIConversation?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isSafetyFiltered: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isSafetyFiltered = isSafetyFiltered
    }

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
}
