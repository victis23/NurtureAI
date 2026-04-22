import Foundation

// MARK: - Week 4 Stub: Push / local notifications

protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleFeedReminder(at date: Date, for baby: Baby) async throws
    func scheduleSleepReminder(at date: Date, for baby: Baby) async throws
    func cancelAllReminders(for baby: Baby) async throws
    func cancelAllReminders() async throws
}

// Stub — replace with UNUserNotificationCenter implementation in Week 4
final class StubNotificationService: NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool { false }
    func scheduleFeedReminder(at date: Date, for baby: Baby) async throws {}
    func scheduleSleepReminder(at date: Date, for baby: Baby) async throws {}
    func cancelAllReminders(for baby: Baby) async throws {}
    func cancelAllReminders() async throws {}
}
