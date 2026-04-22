import Foundation

// MARK: - Week 4 Stub: HealthKit integration

protocol HealthKitServiceProtocol {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func exportSleepLogs(_ logs: [SleepLog]) async throws
    func exportFeedingLogs(_ logs: [FeedingLog]) async throws
    func importGrowthData(for baby: Baby) async throws -> [GrowthMeasurement]
}

// Stub — replace with HealthKit implementation in Week 4
final class StubHealthKitService: HealthKitServiceProtocol {
    var isAvailable: Bool { false }
    func requestAuthorization() async throws {}
    func exportSleepLogs(_ logs: [SleepLog]) async throws {}
    func exportFeedingLogs(_ logs: [FeedingLog]) async throws {}
    func importGrowthData(for baby: Baby) async throws -> [GrowthMeasurement] { [] }
}
