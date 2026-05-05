import Foundation
import SwiftData

/// One round in a conversation: the parent's question + the AI's reply (or
/// the error / in-flight placeholder). Persisted as part of the conversation
/// array so the thread survives app relaunches.
struct AssistTurn: Codable, Identifiable {
    let id: UUID
    let question: String
    var response: AIResponse?
    var errorMessage: String?

    init(id: UUID = UUID(), question: String, response: AIResponse? = nil, errorMessage: String? = nil) {
        self.id = id
        self.question = question
        self.response = response
        self.errorMessage = errorMessage
    }
}

@MainActor
@Observable
final class AssistViewModel {
    private let orchestrator: AIOrchestrating
    private let contextBuilder: BabyContextBuilder
    private let safetyFilter: SafetyFilter
    private let insightRepository: InsightRepositoryProtocol
    let appState: AppState

    var query: String = ""

    /// UserDefaults keys for the persisted conversation. Live outside the
    /// instance so the stored-property initializers below can reference them.
    private static let conversationKey      = "assist.conversation"
    private static let historicalContextKey = "assist.historicalContext"
    /// Pre-conversation key — single `AIResponse` cached as the "last reply".
    /// Replaced by the conversation array; cleared on first launch after
    /// upgrade so we don't leak stale state into the new model.
    private static let legacyLastResponseKey = "assist.lastResponse"

    /// Stored backing for `turns` — what `@Observable` actually tracks. The
    /// computed `turns` below mirrors writes to UserDefaults so the
    /// conversation survives leaving the Assist tab and even a relaunch.
    /// Mirrors the pattern previously used for `parsedResponse`.
    private var _turns: [AssistTurn] = {
        // One-time cleanup of the pre-conversation single-response cache.
        UserDefaults.standard.removeObject(forKey: AssistViewModel.legacyLastResponseKey)

        guard let data = UserDefaults.standard.data(forKey: AssistViewModel.conversationKey),
              let decoded = try? JSONDecoder().decode([AssistTurn].self, from: data)
        else { return [] }
        return decoded
    }()

    var turns: [AssistTurn] {
        get { _turns }
        set {
            _turns = newValue
            persistTurns()
        }
    }

    private var _historicalContext: String? = {
        UserDefaults.standard.string(forKey: AssistViewModel.historicalContextKey)
    }()

    /// Rolling 1–3 sentence summary the model emits and we feed back in on
    /// each follow-up so it can tailor replies to what's already been said.
    var historicalContext: String? {
        get { _historicalContext }
        set {
            _historicalContext = newValue
            if let value = newValue, !value.isEmpty {
                UserDefaults.standard.set(value, forKey: Self.historicalContextKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.historicalContextKey)
            }
        }
    }

    var isStreaming: Bool = false
    var showEscalationBanner: Bool = false
    var emergencyMode: Bool = false
    var error: AIError?
    var dailyQueryCount: Int = 0
    var showPaywall: Bool = false

    private let freeQueryLimit = 3

    /// Keychain-backed counter store. Survives app uninstall, closing the
    /// "delete and reinstall to reset the limit" abuse vector. See
    /// `DailyQuotaStore` for accessibility / threading notes.
    private let quotaStore = DailyQuotaStore()

    var hasReachedFreeLimit: Bool {
        !appState.isSubscribed && dailyQueryCount >= freeQueryLimit
    }

    init(
        orchestrator: AIOrchestrating,
        contextBuilder: BabyContextBuilder,
        safetyFilter: SafetyFilter,
        insightRepository: InsightRepositoryProtocol,
        appState: AppState
    ) {
        self.orchestrator = orchestrator
        self.contextBuilder = contextBuilder
        self.safetyFilter = safetyFilter
        self.insightRepository = insightRepository
        self.appState = appState
        self.dailyQueryCount = loadDailyCount()
    }

    func ask(baby: Baby) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }
        guard !hasReachedFreeLimit else { showPaywall = true; return }

        // Clear the input field as soon as we've committed to processing.
        // `trimmedQuery` is already captured above, so the LLM call still
        // uses the user's original text; the field just looks empty.
        query = ""

        if safetyFilter.requiresEmergencyResponse(trimmedQuery) {
            emergencyMode = true
            showEscalationBanner = true
            return
        }

        // Append the in-flight turn FIRST so the user's question shows on
        // screen immediately under any prior turns, before the network call.
        let turn = AssistTurn(question: trimmedQuery)
        turns.append(turn)
        let turnID = turn.id

        isStreaming = true
        error = nil
        emergencyMode = false

        if safetyFilter.requiresDoctorEscalation(trimmedQuery) {
            showEscalationBanner = true
        } else {
            showEscalationBanner = false
        }

        do {
            let context = try await contextBuilder.context(for: baby)
            let responseJSON = try await orchestrator.ask(
                query: trimmedQuery,
                context: context,
                historicalContext: historicalContext
            )
            let response = try AIResponseParser().parse(responseJSON)
            updateTurn(id: turnID) { $0.response = response }

            let isOffTopic = response.causes.isEmpty && response.confidence == 0
            if !isOffTopic {
                let insight = AIInsight(
                    id: UUID(),
                    createdAt: .now,
                    query: trimmedQuery,
                    responseJSON: responseJSON
                )
                insight.baby = baby
                try insightRepository.save(insight)
                incrementDailyCount()

                // Only refresh the rolling summary on on-topic turns —
                // off-topic replies aren't useful conversational context.
                if let newContext = response.historicalContext?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !newContext.isEmpty {
                    historicalContext = newContext
                }
            }
        } catch let err as AIError {
            error = err
            updateTurn(id: turnID) { $0.errorMessage = err.errorDescription ?? Strings.Assist.errorFallback }
        } catch {
            self.error = .parseError
            updateTurn(id: turnID) { $0.errorMessage = AIError.parseError.errorDescription ?? Strings.Assist.errorFallback }
        }

        isStreaming = false
    }

    func clearQuery() {
        query = ""
        turns = []
        // `historicalContext` intentionally NOT cleared — the rolling summary
        // is the AI's long-term memory of this parent across conversations.
        // It only resets via Settings → Reset AI Memory or sign-out / wipe.
        emergencyMode = false
        showEscalationBanner = false
        error = nil
    }

    /// Hard reset of every persisted Assist artefact: the visible conversation,
    /// the rolling `historical_context` the AI uses as long-term memory, and
    /// the legacy single-response cache. Triggered from Settings → Reset AI
    /// Memory. The next AssistViewModel init will read empty state on the
    /// next visit to the Assist tab.
    ///
    /// Does NOT touch saved `AIInsight` history, daily-quota counters, or
    /// any account / subscription state.
    static func resetAIMemory() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: conversationKey)
        defaults.removeObject(forKey: historicalContextKey)
        defaults.removeObject(forKey: legacyLastResponseKey)
    }

    private func updateTurn(id: UUID, _ mutate: (inout AssistTurn) -> Void) {
        guard let index = _turns.firstIndex(where: { $0.id == id }) else { return }
        var copy = _turns
        mutate(&copy[index])
        turns = copy
    }

    private func persistTurns() {
        if _turns.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.conversationKey)
            return
        }
        if let data = try? JSONEncoder().encode(_turns) {
            UserDefaults.standard.set(data, forKey: Self.conversationKey)
        }
    }

    private func incrementDailyCount() {
        let key = dailyKey()
        let current = quotaStore.count(forKey: key)
        let next = current + 1
        quotaStore.setCount(next, forKey: key)
        dailyQueryCount = next
    }

    private func loadDailyCount() -> Int {
        let key = dailyKey()

        // One-time migration: if Keychain has nothing for today's key but
        // UserDefaults still does (existing user mid-day, app updated to
        // the Keychain-backed implementation), copy the value across and
        // clear the UserDefaults entry so we don't double-count later.
        let keychainCount = quotaStore.count(forKey: key)
        if keychainCount == 0 {
            let legacyCount = UserDefaults.standard.integer(forKey: key)
            if legacyCount > 0 {
                quotaStore.setCount(legacyCount, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
                return legacyCount
            }
        }
        return keychainCount
    }

    private func dailyKey() -> String {
        // Bug #5 fix: `.formatted(.dateTime…)` is locale-sensitive — switching
        // regions (or the user travelling) can change the rendered string and
        // silently reset (or double-count) the daily limit. Use a fixed
        // yyyy-MM-dd key in the user's current calendar instead.
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let year  = components.year  ?? 0
        let month = components.month ?? 0
        let day   = components.day   ?? 0
        return String(format: "queryCount_%04d-%02d-%02d", year, month, day)
    }
}
