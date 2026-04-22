import Foundation
import Observation

@Observable
final class AIAssistantViewModel {
    var messages: [DisplayMessage] = []
    var inputText: String = ""
    var isStreaming = false
    var streamingResponse: String = ""
    var errorMessage: String?
    var currentConversation: AIConversation?

    struct DisplayMessage: Identifiable {
        let id: UUID
        let role: AIMessage.MessageRole
        let content: String
        let timestamp: Date
        let urgencyLevel: ResponseParser.UrgencyLevel
        let suggestedActions: [ResponseParser.SuggestedAction]

        init(from message: AIMessage, urgency: ResponseParser.UrgencyLevel = .normal, actions: [ResponseParser.SuggestedAction] = []) {
            self.id = message.id
            self.role = message.role
            self.content = message.content
            self.timestamp = message.timestamp
            self.urgencyLevel = urgency
            self.suggestedActions = actions
        }
    }

    private let aiService: any AIServiceProtocol
    private let contextBuilder: BabyContextBuilder
    private let safetyFilter: SafetyFilter
    private let responseParser: ResponseParser
    private let conversationRepo: any ConversationRepositoryProtocol

    init(
        aiService: any AIServiceProtocol,
        contextBuilder: BabyContextBuilder,
        safetyFilter: SafetyFilter,
        responseParser: ResponseParser,
        conversationRepo: any ConversationRepositoryProtocol
    ) {
        self.aiService = aiService
        self.contextBuilder = contextBuilder
        self.safetyFilter = safetyFilter
        self.responseParser = responseParser
        self.conversationRepo = conversationRepo
    }

    func loadOrCreateConversation(for baby: Baby) async {
        do {
            let convos = try await conversationRepo.fetchAll(for: baby)
            if let existing = convos.first {
                currentConversation = existing
                messages = existing.messages
                    .sorted { $0.timestamp < $1.timestamp }
                    .map { DisplayMessage(from: $0) }
            } else {
                let convo = AIConversation(title: "\(baby.name)'s Assistant")
                try await conversationRepo.save(convo, for: baby)
                currentConversation = convo
            }
        } catch {
            errorMessage = "Failed to load conversation."
        }
    }

    func send(for baby: Baby) async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isStreaming else { return }

        // Input safety screen
        switch safetyFilter.screenInput(text) {
        case .blocked(let reason):
            appendSystemMessage(reason, urgency: .urgent)
            inputText = ""
            return
        case .requiresMedicalDisclaimer, .allowed:
            break
        }

        inputText = ""

        let userMsg = AIMessage(role: .user, content: text)
        if let convo = currentConversation {
            try? await conversationRepo.addMessage(userMsg, to: convo)
        }
        messages.append(DisplayMessage(from: userMsg))

        isStreaming = true
        streamingResponse = ""

        do {
            let systemPrompt = try await contextBuilder.buildSystemPrompt(for: baby)
            var chatMessages = [ChatMessage.system(systemPrompt)]
            chatMessages += messages.filter { $0.role != .system }.map {
                ChatMessage(role: $0.role.rawValue, content: $0.content)
            }

            let stream = try await aiService.send(messages: chatMessages, stream: true)
            for try await chunk in stream {
                streamingResponse += chunk
            }

            let finalText = safetyFilter.screenOutput(streamingResponse)
            let withDisclaimer = safetyFilter.appendDisclaimerIfNeeded(to: finalText, for: text)
            let parsed = responseParser.parse(withDisclaimer)

            let assistantMsg = AIMessage(role: .assistant, content: withDisclaimer)
            if let convo = currentConversation {
                try? await conversationRepo.addMessage(assistantMsg, to: convo)
            }
            messages.append(DisplayMessage(
                from: assistantMsg,
                urgency: parsed.urgencyLevel,
                actions: parsed.suggestedActions
            ))
        } catch AIError.missingAPIKey {
            errorMessage = "OpenAI API key not configured. Go to Settings to add it."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        streamingResponse = ""
        isStreaming = false
    }

    func clearConversation(for baby: Baby) async {
        guard let convo = currentConversation else { return }
        do {
            try await conversationRepo.delete(convo)
            messages = []
            currentConversation = nil
            await loadOrCreateConversation(for: baby)
        } catch {
            errorMessage = "Failed to clear conversation."
        }
    }

    private func appendSystemMessage(_ content: String, urgency: ResponseParser.UrgencyLevel) {
        let msg = AIMessage(role: .assistant, content: content)
        messages.append(DisplayMessage(from: msg, urgency: urgency))
    }
}
