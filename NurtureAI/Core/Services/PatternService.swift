import Foundation

struct BabyPatterns {
    let avgFeedIntervalMinutes: Int
    let totalSleepTodayMinutes: Int
    let longestSleepStretchMinutes: Int
    let currentAwakeWindowMinutes: Int
    let ageAppropriateMaxAwakeMinutes: Int
    let feedingsToday: Int
    let lastFeedMinutesAgo: Int?
    let lastSleepMinutesAgo: Int?
    let lastDiaperMinutesAgo: Int?
    let sleepTrend: SleepTrend
}

struct PatternService {

    func analyze(logs: [BabyLog], baby: Baby) -> BabyPatterns {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)

        let feedLogs   = logs.filter { $0.type == .feed }
        let sleepLogs  = logs.filter { $0.type == .sleep }
        let diaperLogs = logs.filter { $0.type == .diaper }

        let todayFeeds  = feedLogs.filter { $0.timestamp >= startOfToday }
        let todaySleeps = sleepLogs.filter { $0.timestamp >= startOfToday }

        // Total sleep today
        let totalSleepToday = todaySleeps.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        let totalSleepTodayMinutes = totalSleepToday / 60

        // Longest sleep stretch in window
        let longestSleep = sleepLogs.map { $0.durationSeconds ?? 0 }.max() ?? 0
        let longestSleepMinutes = longestSleep / 60

        // Average feed interval from sorted feed timestamps
        let sortedFeeds = feedLogs.sorted { $0.timestamp < $1.timestamp }
        let avgFeedInterval: Int
        if sortedFeeds.count >= 2 {
            let intervals = zip(sortedFeeds, sortedFeeds.dropFirst()).map {
                Int($1.timestamp.timeIntervalSince($0.timestamp)) / 60
            }
            avgFeedInterval = intervals.reduce(0, +) / intervals.count
        } else {
            avgFeedInterval = 180
        }

        // Feedings today
        let feedingsToday = todayFeeds.count

        // Minutes ago for last of each type
        let lastFeedMinutesAgo: Int? = feedLogs.sorted { $0.timestamp > $1.timestamp }.first.map {
            Int(now.timeIntervalSince($0.timestamp)) / 60
        }

        // Current awake window: time since last sleep ended
        let lastSleepEnd = sleepLogs
            .sorted { $0.timestamp > $1.timestamp }
            .first
            .flatMap { $0.endTimestamp ?? $0.timestamp }
        let currentAwakeWindowMinutes: Int
        let lastSleepMinutesAgo: Int?
        if let sleepEnd = lastSleepEnd {
            let minutesAgo = Int(now.timeIntervalSince(sleepEnd)) / 60
            currentAwakeWindowMinutes = minutesAgo
            lastSleepMinutesAgo = minutesAgo
        } else {
            currentAwakeWindowMinutes = 0
            lastSleepMinutesAgo = nil
        }

        let lastDiaperMinutesAgo: Int? = diaperLogs.sorted { $0.timestamp > $1.timestamp }.first.map {
            Int(now.timeIntervalSince($0.timestamp)) / 60
        }

        // Sleep trend (compare past 3 days vs prior 3 days avg longest stretch)
        let trend = sleepTrend(sleepLogs: logs.filter { $0.type == .sleep }, now: now)

        return BabyPatterns(
            avgFeedIntervalMinutes: avgFeedInterval,
            totalSleepTodayMinutes: totalSleepTodayMinutes,
            longestSleepStretchMinutes: longestSleepMinutes,
            currentAwakeWindowMinutes: currentAwakeWindowMinutes,
            ageAppropriateMaxAwakeMinutes: maxAwakeWindow(ageInWeeks: baby.ageInWeeks),
            feedingsToday: feedingsToday,
            lastFeedMinutesAgo: lastFeedMinutesAgo,
            lastSleepMinutesAgo: lastSleepMinutesAgo,
            lastDiaperMinutesAgo: lastDiaperMinutesAgo,
            sleepTrend: trend
        )
    }

    private func maxAwakeWindow(ageInWeeks: Int) -> Int {
        switch ageInWeeks {
        case 0..<6:   return 60
        case 6..<12:  return 90
        case 12..<20: return 120
        case 20..<28: return 180
        default:      return 210
        }
    }

    private func sleepTrend(sleepLogs: [BabyLog], now: Date) -> SleepTrend {
        let threeDaysAgo = now.addingTimeInterval(-259200)
        let sixDaysAgo   = now.addingTimeInterval(-518400)

        let recentSleeps = sleepLogs.filter { $0.timestamp >= threeDaysAgo }
        let priorSleeps  = sleepLogs.filter { $0.timestamp >= sixDaysAgo && $0.timestamp < threeDaysAgo }

        let recentAvg = recentSleeps.isEmpty ? 0 : recentSleeps.map { $0.durationSeconds ?? 0 }.reduce(0, +) / recentSleeps.count
        let priorAvg  = priorSleeps.isEmpty  ? 0 : priorSleeps.map  { $0.durationSeconds ?? 0 }.reduce(0, +) / priorSleeps.count

        guard priorAvg > 0 else { return .stable }
        let delta = Double(recentAvg - priorAvg) / Double(priorAvg)
        if delta > 0.05 { return .improving }
        if delta < -0.05 { return .declining }
        return .stable
    }
}
