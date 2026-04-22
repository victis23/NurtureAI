import Foundation

struct BabyPatterns {
    let avgFeedIntervalSeconds: Double?
    let avgAwakeWindowSeconds: Double?
    let avgNapDurationSeconds: Double?
    let avgNapCount: Double?
    let avgTotalSleepSeconds: Double?
    let feedingsIn24h: Int
    let mostCommonFeedType: FeedingLog.FeedType?

    var avgFeedIntervalDisplay: String {
        avgFeedIntervalSeconds.map { TimeInterval($0).shortDuration } ?? "Not enough data"
    }
    var avgAwakeWindowDisplay: String {
        avgAwakeWindowSeconds.map { TimeInterval($0).shortDuration } ?? "Not enough data"
    }
    var avgNapDurationDisplay: String {
        avgNapDurationSeconds.map { TimeInterval($0).shortDuration } ?? "Not enough data"
    }

    static let empty = BabyPatterns(
        avgFeedIntervalSeconds: nil,
        avgAwakeWindowSeconds: nil,
        avgNapDurationSeconds: nil,
        avgNapCount: nil,
        avgTotalSleepSeconds: nil,
        feedingsIn24h: 0,
        mostCommonFeedType: nil
    )
}

final class PatternService {

    func analyze(feedings: [FeedingLog], sleeps: [SleepLog]) -> BabyPatterns {
        let sortedFeedings = feedings.sorted { $0.startTime < $1.startTime }
        let sortedSleeps = sleeps.sorted { $0.startTime < $1.startTime }

        return BabyPatterns(
            avgFeedIntervalSeconds: averageFeedInterval(sortedFeedings),
            avgAwakeWindowSeconds: averageAwakeWindow(sortedFeedings, sleeps: sortedSleeps),
            avgNapDurationSeconds: averageNapDuration(sortedSleeps),
            avgNapCount: averageNapCount(sortedSleeps),
            avgTotalSleepSeconds: averageTotalSleep(sortedSleeps),
            feedingsIn24h: feedingsInLast24Hours(sortedFeedings),
            mostCommonFeedType: mostCommonFeedType(sortedFeedings)
        )
    }

    // MARK: - Feed interval

    /// Average time between feed *start* times, in seconds.
    func averageFeedInterval(_ feedings: [FeedingLog]) -> Double? {
        guard feedings.count >= 2 else { return nil }
        let intervals = zip(feedings, feedings.dropFirst()).map { (a, b) in
            b.startTime.timeIntervalSince(a.startTime)
        }.filter { $0 > 0 && $0 < 86400 }  // ignore gaps > 24h (missed logs)
        guard !intervals.isEmpty else { return nil }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    // MARK: - Awake window

    /// Average time awake between sleep end and next sleep start, in seconds.
    func averageAwakeWindow(_ feedings: [FeedingLog], sleeps: [SleepLog]) -> Double? {
        let completedSleeps = sleeps.filter { $0.endTime != nil }
        guard completedSleeps.count >= 2 else { return nil }
        let sorted = completedSleeps.sorted { $0.startTime < $1.startTime }
        let windows = zip(sorted, sorted.dropFirst()).compactMap { (prev, next) -> Double? in
            guard let prevEnd = prev.endTime else { return nil }
            let window = next.startTime.timeIntervalSince(prevEnd)
            guard window > 0 && window < 14400 else { return nil }  // 0–4 hours is plausible
            return window
        }
        guard !windows.isEmpty else { return nil }
        return windows.reduce(0, +) / Double(windows.count)
    }

    // MARK: - Nap duration

    func averageNapDuration(_ sleeps: [SleepLog]) -> Double? {
        let durations = sleeps.compactMap(\.durationSeconds).map(Double.init)
            .filter { $0 > 300 && $0 < 14400 }  // 5 min – 4 hours
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    // MARK: - Nap count per day

    func averageNapCount(_ sleeps: [SleepLog]) -> Double? {
        guard !sleeps.isEmpty else { return nil }
        let byDay = Dictionary(grouping: sleeps) { sleep in
            Calendar.current.startOfDay(for: sleep.startTime)
        }
        guard byDay.count >= 1 else { return nil }
        let dailyCounts = byDay.values.map { Double($0.count) }
        return dailyCounts.reduce(0, +) / Double(dailyCounts.count)
    }

    // MARK: - Total sleep per day

    func averageTotalSleep(_ sleeps: [SleepLog]) -> Double? {
        let completed = sleeps.filter { $0.durationSeconds != nil }
        guard !completed.isEmpty else { return nil }
        let byDay = Dictionary(grouping: completed) { sleep in
            Calendar.current.startOfDay(for: sleep.startTime)
        }
        guard byDay.count >= 1 else { return nil }
        let dailyTotals = byDay.values.map { group in
            group.compactMap(\.durationSeconds).map(Double.init).reduce(0, +)
        }
        return dailyTotals.reduce(0, +) / Double(dailyTotals.count)
    }

    // MARK: - 24-hour feeding count

    func feedingsInLast24Hours(_ feedings: [FeedingLog]) -> Int {
        let cutoff = Date().addingTimeInterval(-86400)
        return feedings.filter { $0.startTime >= cutoff }.count
    }

    // MARK: - Most common feed type

    func mostCommonFeedType(_ feedings: [FeedingLog]) -> FeedingLog.FeedType? {
        guard !feedings.isEmpty else { return nil }
        let counts = Dictionary(grouping: feedings, by: \.type)
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Next feed estimate

    /// Returns estimated next feed time, or nil if insufficient data.
    func estimatedNextFeed(feedings: [FeedingLog]) -> Date? {
        guard let last = feedings.max(by: { $0.startTime < $1.startTime }),
              let interval = averageFeedInterval(feedings.sorted { $0.startTime < $1.startTime })
        else { return nil }
        return last.startTime.addingTimeInterval(interval)
    }

    // MARK: - Overtiredness check

    /// Returns true if baby has been awake longer than their average awake window.
    func isLikelyOvertired(lastSleepEnd: Date?, avgAwakeWindowSeconds: Double?) -> Bool {
        guard let end = lastSleepEnd,
              let window = avgAwakeWindowSeconds else { return false }
        let awakeFor = Date().timeIntervalSince(end)
        return awakeFor > window * 1.2  // 20% buffer
    }
}
