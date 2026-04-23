import XCTest
@testable import NurturAI

final class PatternServiceTests: XCTestCase {

    var sut: PatternService!

    override func setUp() {
        super.setUp()
        sut = PatternService()
    }

    // MARK: - averageFeedInterval

    func test_averageFeedInterval_returnsNil_whenFewerThanTwoFeedings() {
        let feedings = [makeFeed(hoursAgo: 2)]
        XCTAssertNil(sut.averageFeedInterval(feedings))
    }

    func test_averageFeedInterval_calculatesCorrectly_withThreeEvenlySpacedFeedings() {
        let feedings = [
            makeFeed(hoursAgo: 6),
            makeFeed(hoursAgo: 3),
            makeFeed(hoursAgo: 0),
        ]
        let result = sut.averageFeedInterval(feedings.sorted { $0.startTime < $1.startTime })
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 3 * 3600, accuracy: 60)
    }

    func test_averageFeedInterval_ignoresGapsLargerThan24Hours() {
        // 2h gap, 25h gap (should be ignored), 2h gap → avg should be ~2h
        let feedings = [
            makeFeed(hoursAgo: 29),
            makeFeed(hoursAgo: 27),
            makeFeed(hoursAgo: 2),   // 25h gap — ignored
            makeFeed(hoursAgo: 0),
        ]
        let result = sut.averageFeedInterval(feedings.sorted { $0.startTime < $1.startTime })
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 2 * 3600, accuracy: 120)
    }

    // MARK: - averageAwakeWindow

    func test_averageAwakeWindow_returnsNil_withOnlyOneSleep() {
        let sleeps = [makeSleep(hoursAgo: 4, durationHours: 1)]
        XCTAssertNil(sut.averageAwakeWindow([], sleeps: sleeps))
    }

    func test_averageAwakeWindow_calculatesCorrectly() {
        // Sleep 1: ended 6h ago. Sleep 2: started 4.5h ago → awake window = 1.5h
        // Sleep 2: ended 4h ago. Sleep 3: started 2.5h ago → awake window = 1.5h
        let s1 = makeSleepWithTimes(
            start: Date().addingTimeInterval(-7 * 3600),
            end: Date().addingTimeInterval(-6 * 3600)
        )
        let s2 = makeSleepWithTimes(
            start: Date().addingTimeInterval(-4.5 * 3600),
            end: Date().addingTimeInterval(-4 * 3600)
        )
        let s3 = makeSleepWithTimes(
            start: Date().addingTimeInterval(-2.5 * 3600),
            end: Date().addingTimeInterval(-2 * 3600)
        )
        let result = sut.averageAwakeWindow([], sleeps: [s1, s2, s3])
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 1.5 * 3600, accuracy: 60)
    }

    func test_averageAwakeWindow_ignoresWindowsOver4Hours() {
        // 5h awake window should be excluded
        let s1 = makeSleepWithTimes(
            start: Date().addingTimeInterval(-10 * 3600),
            end: Date().addingTimeInterval(-8 * 3600)
        )
        let s2 = makeSleepWithTimes(
            start: Date().addingTimeInterval(-3 * 3600),
            end: Date().addingTimeInterval(-2 * 3600)
        )
        // 5h gap between s1 end and s2 start — filtered out
        let result = sut.averageAwakeWindow([], sleeps: [s1, s2])
        XCTAssertNil(result)
    }

    // MARK: - averageNapDuration

    func test_averageNapDuration_returnsNil_whenNoCompletedSleeps() {
        let ongoing = makeSleep(hoursAgo: 1, durationHours: nil)
        XCTAssertNil(sut.averageNapDuration([ongoing]))
    }

    func test_averageNapDuration_calculatesCorrectly() {
        let sleeps = [
            makeSleep(hoursAgo: 8, durationHours: 1.5),
            makeSleep(hoursAgo: 4, durationHours: 2),
            makeSleep(hoursAgo: 1, durationHours: 0.5),
        ]
        let result = sut.averageNapDuration(sleeps)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, (1.5 + 2 + 0.5) / 3 * 3600, accuracy: 60)
    }

    func test_averageNapDuration_filtersSleepsUnder5Minutes() {
        let sleeps = [
            makeSleepWithDurationSecs(240),  // 4 min — filtered
            makeSleepWithDurationSecs(3600), // 1h
        ]
        let result = sut.averageNapDuration(sleeps)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 3600, accuracy: 60)
    }

    // MARK: - feedingsInLast24Hours

    func test_feedingsInLast24Hours_countsFeedingsWithin24h() {
        let feedings = [
            makeFeed(hoursAgo: 1),
            makeFeed(hoursAgo: 12),
            makeFeed(hoursAgo: 23),
            makeFeed(hoursAgo: 25),  // outside window
        ]
        XCTAssertEqual(sut.feedingsInLast24Hours(feedings), 3)
    }

    // MARK: - estimatedNextFeed

    func test_estimatedNextFeed_returnsNil_withInsufficientData() {
        let feedings = [makeFeed(hoursAgo: 2)]
        XCTAssertNil(sut.estimatedNextFeed(feedings: feedings))
    }

    func test_estimatedNextFeed_addsAverageIntervalToLastFeed() {
        let feedings = [
            makeFeed(hoursAgo: 6),
            makeFeed(hoursAgo: 3),
            makeFeed(hoursAgo: 0),
        ]
        let next = sut.estimatedNextFeed(feedings: feedings)
        XCTAssertNotNil(next)
        XCTAssertEqual(next!.timeIntervalSinceNow, 3 * 3600, accuracy: 120)
    }

    // MARK: - isLikelyOvertired

    func test_isLikelyOvertired_falseWhenUnderWindow() {
        let lastSleepEnd = Date().addingTimeInterval(-1 * 3600)
        let avgWindow = 2.0 * 3600
        XCTAssertFalse(sut.isLikelyOvertired(lastSleepEnd: lastSleepEnd, avgAwakeWindowSeconds: avgWindow))
    }

    func test_isLikelyOvertired_trueWhenOver120PercentOfWindow() {
        let lastSleepEnd = Date().addingTimeInterval(-2.5 * 3600)
        let avgWindow = 2.0 * 3600  // 120% = 2.4h — we've been up 2.5h
        XCTAssertTrue(sut.isLikelyOvertired(lastSleepEnd: lastSleepEnd, avgAwakeWindowSeconds: avgWindow))
    }

    func test_isLikelyOvertired_falseWhenNoData() {
        XCTAssertFalse(sut.isLikelyOvertired(lastSleepEnd: nil, avgAwakeWindowSeconds: nil))
    }

    // MARK: - mostCommonFeedType

    func test_mostCommonFeedType_returnsNil_whenEmpty() {
        XCTAssertNil(sut.mostCommonFeedType([]))
    }

    func test_mostCommonFeedType_returnsCorrectType() {
        let feedings = [
            makeFeed(hoursAgo: 6, type: .breastLeft),
            makeFeed(hoursAgo: 4, type: .breastLeft),
            makeFeed(hoursAgo: 2, type: .bottle),
        ]
        XCTAssertEqual(sut.mostCommonFeedType(feedings), .breastLeft)
    }

    // MARK: - Helpers

    private func makeFeed(
        hoursAgo: Double,
        type: FeedingLog.FeedType = .breastLeft
    ) -> FeedingLog {
        FeedingLog(
            startTime: Date().addingTimeInterval(-hoursAgo * 3600),
            type: type
        )
    }

    private func makeSleep(hoursAgo: Double, durationHours: Double?) -> SleepLog {
        let start = Date().addingTimeInterval(-hoursAgo * 3600)
        let end = durationHours.map { start.addingTimeInterval($0 * 3600) }
        return SleepLog(startTime: start, endTime: end)
    }

    private func makeSleepWithTimes(start: Date, end: Date) -> SleepLog {
        SleepLog(startTime: start, endTime: end)
    }

    private func makeSleepWithDurationSecs(_ secs: Int) -> SleepLog {
        let start = Date().addingTimeInterval(-Double(secs + 3600))
        let end = start.addingTimeInterval(Double(secs))
        return SleepLog(startTime: start, endTime: end)
    }
}
