import Foundation

@MainActor
@Observable
final class BabyContextBuilder {
    private let logRepository: LogRepositoryProtocol
    private let patternService: PatternService

    private(set) var cachedContext: BabyContext?
    private var lastBuilt: Date?

    init(logRepository: LogRepositoryProtocol, patternService: PatternService) {
        self.logRepository = logRepository
        self.patternService = patternService
    }

    func context(for baby: Baby) async throws -> BabyContext {
        if let cached = cachedContext,
           let built = lastBuilt,
           Date().timeIntervalSince(built) < 900 {
            return cached
        }
        return try await rebuild(for: baby)
    }

    func invalidate() {
        cachedContext = nil
        lastBuilt = nil
    }

    private func rebuild(for baby: Baby) async throws -> BabyContext {
        let since24h = Date().addingTimeInterval(-86400)
        let since7d  = Date().addingTimeInterval(-604800)

        let recentLogs = try logRepository.fetchLogs(for: baby, since: since24h)
        let weekLogs   = try logRepository.fetchLogs(for: baby, since: since7d)
        let patterns   = patternService.analyze(logs: recentLogs, baby: baby)

        // 7-day avg longest sleep
        let sleepLogs7d = weekLogs.filter { $0.type == .sleep }
        let sevenDayAvg = sleepLogs7d.isEmpty ? 0 : sleepLogs7d.map { $0.durationSeconds ?? 0 }.reduce(0, +) / sleepLogs7d.count / 60

        // Last feed details
        let lastFeed = recentLogs.filter { $0.type == .feed }.sorted { $0.timestamp > $1.timestamp }.first
        let lastFeedDurationMinutes: Int? = lastFeed?.durationSeconds.map { $0 / 60 }
        let lastFeedSide: String? = {
            guard case .feed(let side, _) = lastFeed?.metadata else { return nil }
            return side.rawValue
        }()

        // Last diaper type
        let lastDiaper = recentLogs.filter { $0.type == .diaper }.sorted { $0.timestamp > $1.timestamp }.first
        let lastDiaperType: String? = {
            guard case .diaper(let type) = lastDiaper?.metadata else { return nil }
            return type.rawValue
        }()

        // Last sleep duration
        let lastSleep = recentLogs.filter { $0.type == .sleep }.sorted { $0.timestamp > $1.timestamp }.first
        let lastSleepDurationMinutes: Int? = lastSleep?.durationSeconds.map { $0 / 60 }

        let gramsToLbs = { (grams: Int) -> Double in Double(grams) * 0.00220462 }

        let challenges = baby.childcareChallenges.compactMap(ChildcareChallenge.init(rawValue:))

        let ctx = BabyContext(
            babyName: baby.name,
            ageInWeeks: baby.ageInWeeks,
            feedingMethod: baby.feedingMethod.displayName,
            birthWeightLbs: gramsToLbs(baby.birthWeightGrams),
            currentWeightLbs: gramsToLbs(baby.currentWeightGrams),
            sensitivities: baby.sensitivities,
            developmentalStage: BabyContext.developmentalStage(ageInWeeks: baby.ageInWeeks),
            isFirstChild: baby.isFirstChild,
            familySupport: baby.familySupport,
            overwhelmLevel: baby.overwhelmLevel,
            emotionalWellbeing: baby.emotionalWellbeing,
            householdType: baby.householdType,
            pediatricianVisitFrequency: baby.pediatricianVisitFrequency,
            childcareChallenges: challenges,
            teethingStatus: baby.teethingStatus,
            solidFoodStatus: baby.solidFoodStatus,
            typicalFeedingFrequency: baby.feedingFrequency,
            bathingFrequency: baby.bathingFrequency,
            lastFeedMinutesAgo: patterns.lastFeedMinutesAgo,
            lastFeedDurationMinutes: lastFeedDurationMinutes,
            lastFeedSide: lastFeedSide,
            feedingsToday: patterns.feedingsToday,
            avgFeedIntervalMinutes: patterns.avgFeedIntervalMinutes,
            lastSleepMinutesAgo: patterns.lastSleepMinutesAgo,
            lastSleepDurationMinutes: lastSleepDurationMinutes,
            totalSleepTodayHours: Double(patterns.totalSleepTodayMinutes) / 60.0,
            currentAwakeWindowMinutes: patterns.currentAwakeWindowMinutes,
            ageAppropriateMaxAwakeMinutes: patterns.ageAppropriateMaxAwakeMinutes,
            lastDiaperMinutesAgo: patterns.lastDiaperMinutesAgo,
            lastDiaperType: lastDiaperType,
            sevenDayAvgLongestSleepMinutes: sevenDayAvg,
            sleepTrend: patterns.sleepTrend.rawValue
        )

        cachedContext = ctx
        lastBuilt = .now
        return ctx
    }
}
