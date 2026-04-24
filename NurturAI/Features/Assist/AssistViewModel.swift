import Foundation
import SwiftData

@MainActor
@Observable
final class AssistViewModel {
    private let orchestrator: AIOrchestrating
    private let contextBuilder: BabyContextBuilder
    private let safetyFilter: SafetyFilter
    private let insightRepository: InsightRepositoryProtocol
    let appState: AppState

    var query: String = ""
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

        // Clear the input field as soon as we've committed to processing.
        // `trimmedQuery` is already captured above, so the LLM call still
        // uses the user's original text; the field just looks empty.
        query = ""

        if safetyFilter.requiresEmergencyResponse(trimmedQuery) {
            emergencyMode = true
            showEscalationBanner = true
            return
        }

        parsedResponse = nil
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
            let responseJSON = try await orchestrator.ask(query: trimmedQuery, context: context)
            let response = try AIResponseParser().parse(responseJSON)
            parsedResponse = response

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
            }
        } catch let err as AIError {
            error = err
        } catch {
            self.error = .parseError
        }

        isStreaming = false
    }

    func clearQuery() {
        query = ""
        parsedResponse = nil
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
