import Foundation

@MainActor
@Observable
final class AssistViewModel {
    private let orchestrator: AIOrchestrating
    private let contextBuilder: BabyContextBuilder
    private let safetyFilter: SafetyFilter
    private let insightRepository: InsightRepositoryProtocol
    let appState: AppState

    var query: String = ""
    var streamingText: String = ""
    var parsedResponse: AIResponse?
    var isStreaming: Bool = false
    var showEscalationBanner: Bool = false
    var emergencyMode: Bool = false
    var error: AIError?
    var dailyQueryCount: Int = 0
    var showPaywall: Bool = false

    private let freeQueryLimit = 3

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

        if safetyFilter.requiresEmergencyResponse(trimmedQuery) {
            emergencyMode = true
            showEscalationBanner = true
            return
        }

        parsedResponse = nil
        streamingText = ""
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
            var accumulated = ""

            for try await token in orchestrator.stream(query: trimmedQuery, context: context) {
                accumulated += token
                streamingText = accumulated
            }

            let response = try AIResponseParser().parse(accumulated)
            parsedResponse = response

            let insight = AIInsight(
                id: UUID(),
                createdAt: .now,
                query: trimmedQuery,
                responseJSON: accumulated
            )
            insight.baby = baby
            try insightRepository.save(insight)

            incrementDailyCount()
        } catch let err as AIError {
            error = err
        } catch {
            self.error = .invalidResponse
        }

        isStreaming = false
    }

    func clearQuery() {
        query = ""
        parsedResponse = nil
        streamingText = ""
        emergencyMode = false
        showEscalationBanner = false
        error = nil
    }

    private func incrementDailyCount() {
        let key = dailyKey()
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        dailyQueryCount = current + 1
    }

    private func loadDailyCount() -> Int {
        UserDefaults.standard.integer(forKey: dailyKey())
    }

    private func dailyKey() -> String {
        "queryCount_\(Date().formatted(.dateTime.year().month().day()))"
    }
}
