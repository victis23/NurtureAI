import Foundation

/// Builds and caches the baby context string injected into every AI system prompt.
/// Call `invalidate(for:)` immediately after every LogRepository.save() / delete() / update().
final class BabyContextBuilder {
    private var cache: [UUID: CachedContext] = [:]
    private let lock = NSLock()
    private let feedingRepo: FeedingLogRepositoryProtocol
    private let sleepRepo: SleepLogRepositoryProtocol
    private let diaperRepo: DiaperLogRepositoryProtocol
    private let patternService: PatternService

    private struct CachedContext {
        let context: BabyContext
        let builtAt: Date
    }

    init(
        feedingRepo: FeedingLogRepositoryProtocol,
        sleepRepo: SleepLogRepositoryProtocol,
        diaperRepo: DiaperLogRepositoryProtocol,
        patternService: PatternService
    ) {
        self.feedingRepo = feedingRepo
        self.sleepRepo = sleepRepo
        self.diaperRepo = diaperRepo
        self.patternService = patternService
    }

    func invalidate(for baby: Baby) {
        lock.withLock { cache.removeValue(forKey: baby.id) }
    }

    func build(for baby: Baby) async throws -> BabyContext {
        if let cached = lock.withLock({ cache[baby.id] }) {
            return cached.context
        }

        let recentFeedings = try await feedingRepo.fetchRecent(for: baby, limit: 10)
        let recentSleeps = try await sleepRepo.fetchRecent(for: baby, limit: 10)
        let recentDiapers = try await diaperRepo.fetchRecent(for: baby, limit: 5)
        let lastFeeding = recentFeedings.first
        let lastSleep = recentSleeps.first
        let patterns = patternService.analyze(feedings: recentFeedings, sleeps: recentSleeps)

        let context = BabyContext(
            baby: baby,
            lastFeeding: lastFeeding,
            lastSleep: lastSleep,
            recentDiapers: recentDiapers,
            patterns: patterns,
            builtAt: Date()
        )

        lock.withLock { cache[baby.id] = CachedContext(context: context, builtAt: Date()) }
        return context
    }

    func buildSystemPrompt(for baby: Baby) async throws -> String {
        let ctx = try await build(for: baby)
        return ctx.toSystemPrompt()
    }
}

// MARK: - BabyContext value type

struct BabyContext {
    let baby: Baby
    let lastFeeding: FeedingLog?
    let lastSleep: SleepLog?
    let recentDiapers: [DiaperLog]
    let patterns: BabyPatterns
    let builtAt: Date

    func toSystemPrompt() -> String {
        var lines: [String] = []
        lines.append("You are a knowledgeable, warm baby care assistant for \(baby.name)'s parents.")
        lines.append("Today is \(Date().formatted(date: .long, time: .shortened)).")
        lines.append("\(baby.name) is \(baby.ageDescription).")

        if let feed = lastFeeding {
            let ago = Date().timeIntervalSince(feed.startTime)
            lines.append("Last feeding: \(feed.type.rawValue), \(ago.shortDuration) ago\(feed.amountMl.map { " (\(Int($0)) ml)" } ?? "").")
        } else {
            lines.append("No feeding logged yet today.")
        }

        if let sleep = lastSleep {
            if sleep.isOngoing {
                lines.append("\(baby.name) is currently sleeping (started \(Date().timeIntervalSince(sleep.startTime).shortDuration) ago).")
            } else if let end = sleep.endTime {
                let ago = Date().timeIntervalSince(end)
                lines.append("Last sleep ended \(ago.shortDuration) ago, duration: \(sleep.durationDisplay).")
            }
        } else {
            lines.append("No sleep logged yet today.")
        }

        lines.append("Average feed interval: \(patterns.avgFeedIntervalDisplay).")
        lines.append("Average awake window: \(patterns.avgAwakeWindowDisplay).")
        lines.append("Average nap duration: \(patterns.avgNapDurationDisplay).")

        lines.append("""

        IMPORTANT GUIDELINES:
        - Always recommend consulting a pediatrician for medical concerns.
        - Never diagnose conditions or prescribe treatments.
        - Flag urgent situations (high fever, difficulty breathing, unusual color) immediately.
        - Base suggestions on \(baby.name)'s actual age (\(baby.ageDescription)) and logged data.
        - Be concise, warm, and practical.
        """)

        return lines.joined(separator: "\n")
    }
}
