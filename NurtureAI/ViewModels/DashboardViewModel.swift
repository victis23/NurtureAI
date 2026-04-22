import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    var baby: Baby?
    var patterns: BabyPatterns = .empty
    var lastFeeding: FeedingLog?
    var lastSleep: SleepLog?
    var recentDiapers: [DiaperLog] = []
    var estimatedNextFeed: Date?
    var isOvertired: Bool = false
    var isLoading = false
    var errorMessage: String?

    private let contextBuilder: BabyContextBuilder
    private let patternService: PatternService
    private let feedingRepo: any FeedingLogRepositoryProtocol
    private let sleepRepo: any SleepLogRepositoryProtocol
    private let diaperRepo: any DiaperLogRepositoryProtocol

    init(
        contextBuilder: BabyContextBuilder,
        patternService: PatternService,
        feedingRepo: any FeedingLogRepositoryProtocol,
        sleepRepo: any SleepLogRepositoryProtocol,
        diaperRepo: any DiaperLogRepositoryProtocol
    ) {
        self.contextBuilder = contextBuilder
        self.patternService = patternService
        self.feedingRepo = feedingRepo
        self.sleepRepo = sleepRepo
        self.diaperRepo = diaperRepo
    }

    func load(baby: Baby) async {
        self.baby = baby
        isLoading = true
        defer { isLoading = false }
        do {
            let ctx = try await contextBuilder.build(for: baby)
            self.patterns = ctx.patterns
            self.lastFeeding = ctx.lastFeeding
            self.lastSleep = ctx.lastSleep
            self.recentDiapers = ctx.recentDiapers

            let recentFeeds = try await feedingRepo.fetchRecent(for: baby, limit: 20)
            self.estimatedNextFeed = patternService.estimatedNextFeed(feedings: recentFeeds)
            self.isOvertired = patternService.isLikelyOvertired(
                lastSleepEnd: lastSleep?.endTime,
                avgAwakeWindowSeconds: patterns.avgAwakeWindowSeconds
            )
        } catch {
            errorMessage = "Failed to load dashboard."
        }
    }

    func refresh(baby: Baby) async {
        contextBuilder.invalidate(for: baby)
        await load(baby: baby)
    }

    // MARK: - Computed display helpers

    var timeSinceLastFeedDisplay: String {
        guard let feed = lastFeeding else { return "No feeding logged" }
        let interval = Date().timeIntervalSince(feed.startTime)
        return "\(interval.shortDuration) ago"
    }

    var timeSinceLastSleepDisplay: String {
        guard let sleep = lastSleep else { return "No sleep logged" }
        if sleep.isOngoing {
            return "Sleeping now (\(Date().timeIntervalSince(sleep.startTime).shortDuration))"
        }
        guard let end = sleep.endTime else { return "—" }
        return "Awake \(Date().timeIntervalSince(end).shortDuration)"
    }

    var nextFeedDisplay: String {
        guard let next = estimatedNextFeed else { return "Not enough data" }
        if next < Date() { return "Feed overdue" }
        let interval = next.timeIntervalSince(Date())
        return "In \(interval.shortDuration)"
    }
}
