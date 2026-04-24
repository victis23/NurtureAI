import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject {

    // MARK: - Notification identifiers

    private enum ID {
        static let feed           = "nurtur.notification.feed"
        static let feedFollowup   = "nurtur.notification.feed.followup"
        static let sleep          = "nurtur.notification.sleep"
        static let sleepFollowup  = "nurtur.notification.sleep.followup"
        static let diaper         = "nurtur.notification.diaper"
        static let diaperFollowup = "nurtur.notification.diaper.followup"

        static let all: [String] = [
            feed, feedFollowup,
            sleep, sleepFollowup,
            diaper, diaperFollowup
        ]
    }

    /// Minutes after the primary notification fires before the follow-up reminder fires.
    private static let followupDelayMinutes = 30

    // MARK: - State

    private(set) var isAuthorized = false
    private let center = UNUserNotificationCenter.current()

    // MARK: - Init

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    /// Requests permission if not yet determined; updates isAuthorized from the current status.
    func requestPermission() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
        case .notDetermined:
            do {
                isAuthorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                isAuthorized = false
            }
        default:
            isAuthorized = false
        }
    }

    // MARK: - Schedule

    /// Cancels and reschedules all three notification types based on the latest patterns.
    /// Safe to call on every data refresh — each type uses a stable identifier so only
    /// one pending notification per type ever exists.
    func scheduleNotifications(
        for baby: Baby,
        patterns: BabyPatterns,
        activeSessions: [LogType: ActiveTimerSession]
    ) async {
        guard isAuthorized else { return }
        await scheduleFeedNotification(baby: baby, patterns: patterns, activeSessions: activeSessions)
        await scheduleSleepNotification(baby: baby, patterns: patterns, activeSessions: activeSessions)
        await scheduleDiaperNotification(baby: baby, patterns: patterns)
    }

    /// Removes all pending NurturAI notifications (e.g. on sign-out).
    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: ID.all)
    }

    // MARK: - Feed

    private func scheduleFeedNotification(
        baby: Baby,
        patterns: BabyPatterns,
        activeSessions: [LogType: ActiveTimerSession]
    ) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.feed, ID.feedFollowup])

        // Skip if a feed timer is currently running
        guard activeSessions[.feed] == nil else { return }
        guard let lastFeedMinutesAgo = patterns.lastFeedMinutesAgo else { return }

        let minutesUntilDue = patterns.avgFeedIntervalMinutes - lastFeedMinutesAgo
        guard minutesUntilDue > 0 else { return }

        let primary = UNMutableNotificationContent()
        primary.title = "Time to feed \(baby.name)"
        primary.body  = "It's been \(lastFeedMinutesAgo) min since the last feeding."
        primary.sound = .default

        await schedule(id: ID.feed, content: primary, inMinutes: minutesUntilDue)

        // Follow-up reminder if the primary is ignored.
        let followup = UNMutableNotificationContent()
        followup.title = "\(baby.name) still needs to be fed"
        followup.body  = "It's been a while since the last feeding — don't forget to log it."
        followup.sound = .default

        await schedule(
            id: ID.feedFollowup,
            content: followup,
            inMinutes: minutesUntilDue + Self.followupDelayMinutes
        )
    }

    // MARK: - Sleep

    private func scheduleSleepNotification(
        baby: Baby,
        patterns: BabyPatterns,
        activeSessions: [LogType: ActiveTimerSession]
    ) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.sleep, ID.sleepFollowup])

        // Skip if baby is already sleeping
        guard activeSessions[.sleep] == nil else { return }
        // Skip if no sleep has ever been logged — awake window is unreliable
        guard patterns.lastSleepMinutesAgo != nil else { return }

        let minutesUntilDue = patterns.ageAppropriateMaxAwakeMinutes - patterns.currentAwakeWindowMinutes
        guard minutesUntilDue > 0 else { return }

        let primary = UNMutableNotificationContent()
        primary.title = "\(baby.name) may be getting tired"
        primary.body  = "\(baby.name) has been awake for \(patterns.currentAwakeWindowMinutes) min — approaching the \(patterns.ageAppropriateMaxAwakeMinutes) min limit."
        primary.sound = .default

        await schedule(id: ID.sleep, content: primary, inMinutes: minutesUntilDue)

        // Follow-up reminder if the primary is ignored.
        let followup = UNMutableNotificationContent()
        followup.title = "\(baby.name) is past their awake window"
        followup.body  = "Overtired babies struggle to fall asleep — try winding down soon."
        followup.sound = .default

        await schedule(
            id: ID.sleepFollowup,
            content: followup,
            inMinutes: minutesUntilDue + Self.followupDelayMinutes
        )
    }

    // MARK: - Diaper

    private func scheduleDiaperNotification(baby: Baby, patterns: BabyPatterns) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.diaper, ID.diaperFollowup])

        guard let lastDiaperMinutesAgo = patterns.lastDiaperMinutesAgo else { return }

        // Age-based recommended diaper check interval
        let intervalMinutes: Int
        switch baby.ageInWeeks {
        case 0..<12:  intervalMinutes = 120   // every 2 h for newborns
        case 12..<24: intervalMinutes = 180   // every 3 h for 3–6 months
        default:      intervalMinutes = 240   // every 4 h for 6+ months
        }

        let minutesUntilDue = intervalMinutes - lastDiaperMinutesAgo
        guard minutesUntilDue > 0 else { return }

        let primary = UNMutableNotificationContent()
        primary.title = "Time to check \(baby.name)'s diaper"
        primary.body  = "It's been \(lastDiaperMinutesAgo) min since the last diaper change."
        primary.sound = .default

        await schedule(id: ID.diaper, content: primary, inMinutes: minutesUntilDue)

        // Follow-up reminder if the primary is ignored.
        let followup = UNMutableNotificationContent()
        followup.title = "\(baby.name)'s diaper still needs checking"
        followup.body  = "Don't forget to check and log a diaper change."
        followup.sound = .default

        await schedule(
            id: ID.diaperFollowup,
            content: followup,
            inMinutes: minutesUntilDue + Self.followupDelayMinutes
        )
    }

    // MARK: - Helpers

    private func schedule(id: String, content: UNMutableNotificationContent, inMinutes minutes: Int) async {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show banner + sound even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
