import Foundation
import SwiftData
import Observation

@Observable
final class DependencyContainer {

    // MARK: - SwiftData

    let modelContainer: ModelContainer

    // MARK: - Repositories

    let babyRepository: any BabyRepositoryProtocol
    let feedingLogRepository: any FeedingLogRepositoryProtocol
    let sleepLogRepository: any SleepLogRepositoryProtocol
    let diaperLogRepository: any DiaperLogRepositoryProtocol
    let growthRepository: any GrowthRepositoryProtocol
    let conversationRepository: any ConversationRepositoryProtocol

    // MARK: - Services (production)

    let patternService: PatternService
    let contextBuilder: BabyContextBuilder
    let safetyFilter: SafetyFilter
    let responseParser: ResponseParser
    let aiService: any AIServiceProtocol

    // MARK: - Services (Week 4 stubs — swap implementations here)

    let storeKitService: any StoreKitServiceProtocol
    let healthKitService: any HealthKitServiceProtocol
    let notificationService: any NotificationServiceProtocol
    let predictionService: any PredictionServiceProtocol
    let caregiverService: any CaregiverServiceProtocol

    // MARK: - Init

    init() {
        let schema = Schema([
            Baby.self, FeedingLog.self, SleepLog.self,
            DiaperLog.self, GrowthMeasurement.self,
            AIConversation.self, AIMessage.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.modelContainer = container

        let context = ModelContext(container)
        let pattern = PatternService()
        self.patternService = pattern

        // Phase 1 — create repos without contextBuilder
        let feeding = SwiftDataFeedingLogRepository(modelContext: context)
        let sleep = SwiftDataSleepLogRepository(modelContext: context)
        let diaper = SwiftDataDiaperLogRepository(modelContext: context)

        // Phase 2 — create contextBuilder with repos, then inject back
        let ctxBuilder = BabyContextBuilder(
            feedingRepo: feeding,
            sleepRepo: sleep,
            diaperRepo: diaper,
            patternService: pattern
        )
        feeding.injectContextBuilder(ctxBuilder)
        sleep.injectContextBuilder(ctxBuilder)
        diaper.injectContextBuilder(ctxBuilder)

        self.contextBuilder = ctxBuilder
        self.feedingLogRepository = feeding
        self.sleepLogRepository = sleep
        self.diaperLogRepository = diaper
        self.babyRepository = SwiftDataBabyRepository(modelContext: context)
        self.growthRepository = SwiftDataGrowthRepository(modelContext: context)
        self.conversationRepository = SwiftDataConversationRepository(modelContext: context)

        self.safetyFilter = SafetyFilter()
        self.responseParser = ResponseParser()
        self.aiService = OpenAIService()

        // Week 4 stubs
        self.storeKitService = StubStoreKitService()
        self.healthKitService = StubHealthKitService()
        self.notificationService = StubNotificationService()
        self.predictionService = StubPredictionService(patternService: pattern)
        self.caregiverService = StubCaregiverService()
    }
}
