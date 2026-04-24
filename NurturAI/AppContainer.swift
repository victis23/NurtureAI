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
    let timerService: ActiveTimerService
    // Stored as the concrete `@Observable` type (mirroring `timerService` above)
    // so SwiftUI views can observe loading / error / status changes directly.
    // Code that only needs the protocol can still upcast at the use-site.
    let subscriptionService: StoreKitSubscriptionService
    let authService: AuthServiceProtocol
    let notificationService: NotificationService

    @MainActor
    static func live(modelContext: ModelContext) -> AppContainer {
        let babyRepo    = BabyRepository(context: modelContext)
        let logRepo     = LogRepository(context: modelContext)
        let insightRepo = InsightRepository(context: modelContext)
        let patterns    = PatternService()
        let builder     = BabyContextBuilder(logRepository: logRepo, patternService: patterns)
        let orchestrator = AIOrchestrator()
        let syncService  = FirestoreSyncService(db: Firestore.firestore(), logRepository: logRepo)
        let timerService = ActiveTimerService(
            logRepository: logRepo,
            syncService: syncService,
            contextBuilder: builder
        )
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
            timerService: timerService,
            subscriptionService: subscriptionService,
            authService: AuthService(),
            notificationService: NotificationService()
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
