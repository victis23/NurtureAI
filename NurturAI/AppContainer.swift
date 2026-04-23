import SwiftUI
import SwiftData
import FirebaseFirestore

struct AppContainer {
    let modelContext: ModelContext
    let babyRepository: BabyRepositoryProtocol
    let logRepository: LogRepositoryProtocol
    let insightRepository: InsightRepositoryProtocol
    let patternService: PatternService
    let contextBuilder: BabyContextBuilder
    let orchestrator: AIOrchestrating
    let safetyFilter: SafetyFilter
    let syncService: FirestoreSyncService
    let subscriptionService: SubscriptionServiceProtocol
    let authService: AuthServiceProtocol

    @MainActor
    static func live(modelContext: ModelContext) -> AppContainer {
        let babyRepo    = BabyRepository(context: modelContext)
        let logRepo     = LogRepository(context: modelContext)
        let insightRepo = InsightRepository(context: modelContext)
        let patterns    = PatternService()
        let builder     = BabyContextBuilder(logRepository: logRepo, patternService: patterns)
        let orchestrator = AIOrchestrator()
        let syncService  = FirestoreSyncService(db: Firestore.firestore(), logRepository: logRepo)
        let subscriptionService = StoreKitSubscriptionService(appState: AppState.shared)
        subscriptionService.start()

        return AppContainer(
            modelContext: modelContext,
            babyRepository: babyRepo,
            logRepository: logRepo,
            insightRepository: insightRepo,
            patternService: patterns,
            contextBuilder: builder,
            orchestrator: orchestrator,
            safetyFilter: SafetyFilter(),
            syncService: syncService,
            subscriptionService: subscriptionService,
            authService: AuthService()
        )
    }
}

// MARK: - Environment

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue: AppContainer? = nil
}

extension EnvironmentValues {
    var appContainer: AppContainer? {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
