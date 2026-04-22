import Foundation

// MARK: - Week 4 Stub: Sleep regression + milestone prediction

protocol PredictionServiceProtocol {
    func predictNextFeed(for baby: Baby, patterns: BabyPatterns) -> Date?
    func predictNextSleep(for baby: Baby, lastSleepEnd: Date?, patterns: BabyPatterns) -> Date?
    func isSleepRegressionLikely(for baby: Baby, patterns: BabyPatterns) -> SleepRegressionRisk
}

struct SleepRegressionRisk {
    let likelihood: Double  // 0.0–1.0
    let reason: String?
    static let none = SleepRegressionRisk(likelihood: 0, reason: nil)
}

// Stub — replace with Core ML / statistical model in Week 4
final class StubPredictionService: PredictionServiceProtocol {
    private let patternService: PatternService

    init(patternService: PatternService) {
        self.patternService = patternService
    }

    func predictNextFeed(for baby: Baby, patterns: BabyPatterns) -> Date? { nil }
    func predictNextSleep(for baby: Baby, lastSleepEnd: Date?, patterns: BabyPatterns) -> Date? { nil }
    func isSleepRegressionLikely(for baby: Baby, patterns: BabyPatterns) -> SleepRegressionRisk { .none }
}
