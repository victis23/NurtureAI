import Foundation
import OSLog
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject {

    // MARK: - Notification identifiers

    private enum ID {
        static let feed           = "nurtur.notification.feed"
        static let feedFollowup   = "nurtur.notification.feed.followup"
        static let feedEsc1       = "nurtur.notification.feed.esc1"
        static let feedEsc2       = "nurtur.notification.feed.esc2"
        static let sleep          = "nurtur.notification.sleep"
        static let sleepFollowup  = "nurtur.notification.sleep.followup"
        static let sleepEsc1      = "nurtur.notification.sleep.esc1"
        static let sleepEsc2      = "nurtur.notification.sleep.esc2"
        static let diaper         = "nurtur.notification.diaper"
        static let diaperFollowup = "nurtur.notification.diaper.followup"
        static let diaperEsc1     = "nurtur.notification.diaper.esc1"
        static let diaperEsc2     = "nurtur.notification.diaper.esc2"

        static let feedAll:   [String] = [feed,   feedFollowup,   feedEsc1,   feedEsc2]
        static let sleepAll:  [String] = [sleep,  sleepFollowup,  sleepEsc1,  sleepEsc2]
        static let diaperAll: [String] = [diaper, diaperFollowup, diaperEsc1, diaperEsc2]

        static let all: [String] = feedAll + sleepAll + diaperAll
    }

    /// Minutes after the primary notification fires before the follow-up reminder fires.
    private static let followupDelayMinutes = 30

    /// Once `minutesUntilDue` is at or below the negative of these thresholds,
    /// the parent is "severely overdue". Two extra escalation reminders fire
    /// at this offset and one hour later. Sleep is tighter because the awake
    /// cap is a max, not an average.
    static let feedSeverelyOverdueMinutes   = 60
    static let diaperSeverelyOverdueMinutes = 60
    static let sleepSeverelyOverdueMinutes  = 15

    /// Skip a slot whose fire offset is more than this far in the past at
    /// schedule time. Past this, assume the parent intentionally skipped
    /// (long outing, baby slept through, etc.) and don't pile on stale pings.
    private static let staleSkipMinutes = 240

    /// Bug #6 fix: scheduling failures used to be swallowed by `try?`. The most
    /// common cause is hitting iOS's 64-pending-notification ceiling, which
    /// silently breaks reminders. Surface failures via OSLog so we can see them
    /// in Console.app and (eventually) in crash analytics.
    private static let logger = Logger(subsystem: "ai.nurtur.app", category: "Notifications")

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
        // Skip if a feed timer is currently running
        guard activeSessions[.feed] == nil else {
            center.removePendingNotificationRequests(withIdentifiers: ID.feedAll)
            return
        }
        guard let lastFeedMinutesAgo = patterns.lastFeedMinutesAgo else {
            center.removePendingNotificationRequests(withIdentifiers: ID.feedAll)
            return
        }

        let minutesUntilDue = patterns.avgFeedIntervalMinutes - lastFeedMinutesAgo

        let primary = UNMutableNotificationContent()
        primary.title = Strings.Notifications.Feed.primaryTitle(baby.name)
        primary.body  = Strings.Notifications.Feed.primaryBody(max(0, lastFeedMinutesAgo))
        primary.sound = .default

        let followup = UNMutableNotificationContent()
        followup.title = Strings.Notifications.Feed.followupTitle(baby.name)
        followup.body  = Strings.Notifications.Feed.followupBody
        followup.sound = .default

        let esc1 = UNMutableNotificationContent()
        esc1.title = Strings.Notifications.Feed.escalation1Title(baby.name)
        esc1.body  = Strings.Notifications.Feed.escalation1Body
        esc1.sound = .default

        let esc2 = UNMutableNotificationContent()
        esc2.title = Strings.Notifications.Feed.escalation2Title(baby.name)
        esc2.body  = Strings.Notifications.Feed.escalation2Body
        esc2.sound = .default

        let severe = Self.feedSeverelyOverdueMinutes
        let slots: [(id: String, offset: Int, content: UNMutableNotificationContent)] = [
            (ID.feed,         minutesUntilDue,                                 primary),
            (ID.feedFollowup, minutesUntilDue + Self.followupDelayMinutes,     followup),
            (ID.feedEsc1,     minutesUntilDue + severe,                        esc1),
            (ID.feedEsc2,     minutesUntilDue + severe + 60,                   esc2),
        ]

        await scheduleSlots(slots, allIDs: ID.feedAll)
    }

    // MARK: - Sleep

    private func scheduleSleepNotification(
        baby: Baby,
        patterns: BabyPatterns,
        activeSessions: [LogType: ActiveTimerSession]
    ) async {
        // Skip if baby is already sleeping
        guard activeSessions[.sleep] == nil else {
            center.removePendingNotificationRequests(withIdentifiers: ID.sleepAll)
            return
        }
        // Skip if no sleep has ever been logged — awake window is unreliable
        guard patterns.lastSleepMinutesAgo != nil else {
            center.removePendingNotificationRequests(withIdentifiers: ID.sleepAll)
            return
        }

        let minutesUntilDue = patterns.ageAppropriateMaxAwakeMinutes - patterns.currentAwakeWindowMinutes

        let primary = UNMutableNotificationContent()
        primary.title = Strings.Notifications.Sleep.primaryTitle(baby.name)
        primary.body  = Strings.Notifications.Sleep.primaryBody(
            baby.name,
            awakeMinutes: patterns.currentAwakeWindowMinutes,
            maxMinutes: patterns.ageAppropriateMaxAwakeMinutes
        )
        primary.sound = .default

        let followup = UNMutableNotificationContent()
        followup.title = Strings.Notifications.Sleep.followupTitle(baby.name)
        followup.body  = Strings.Notifications.Sleep.followupBody
        followup.sound = .default

        let esc1 = UNMutableNotificationContent()
        esc1.title = Strings.Notifications.Sleep.escalation1Title(baby.name)
        esc1.body  = Strings.Notifications.Sleep.escalation1Body
        esc1.sound = .default

        let esc2 = UNMutableNotificationContent()
        esc2.title = Strings.Notifications.Sleep.escalation2Title(baby.name)
        esc2.body  = Strings.Notifications.Sleep.escalation2Body
        esc2.sound = .default

        let severe = Self.sleepSeverelyOverdueMinutes
        let slots: [(id: String, offset: Int, content: UNMutableNotificationContent)] = [
            (ID.sleep,         minutesUntilDue,                              primary),
            (ID.sleepFollowup, minutesUntilDue + Self.followupDelayMinutes,  followup),
            (ID.sleepEsc1,     minutesUntilDue + severe,                     esc1),
            (ID.sleepEsc2,     minutesUntilDue + severe + 60,                esc2),
        ]

        await scheduleSlots(slots, allIDs: ID.sleepAll)
    }

    // MARK: - Diaper

    private func scheduleDiaperNotification(baby: Baby, patterns: BabyPatterns) async {
        guard let lastDiaperMinutesAgo = patterns.lastDiaperMinutesAgo else {
            center.removePendingNotificationRequests(withIdentifiers: ID.diaperAll)
            return
        }

        let intervalMinutes = Self.diaperIntervalMinutes(forAgeInWeeks: baby.ageInWeeks)
        let minutesUntilDue = intervalMinutes - lastDiaperMinutesAgo

        let primary = UNMutableNotificationContent()
        primary.title = Strings.Notifications.Diaper.primaryTitle(baby.name)
        primary.body  = Strings.Notifications.Diaper.primaryBody(max(0, lastDiaperMinutesAgo))
        primary.sound = .default

        let followup = UNMutableNotificationContent()
        followup.title = Strings.Notifications.Diaper.followupTitle(baby.name)
        followup.body  = Strings.Notifications.Diaper.followupBody
        followup.sound = .default

        let esc1 = UNMutableNotificationContent()
        esc1.title = Strings.Notifications.Diaper.escalation1Title(baby.name)
        esc1.body  = Strings.Notifications.Diaper.escalation1Body
        esc1.sound = .default

        let esc2 = UNMutableNotificationContent()
        esc2.title = Strings.Notifications.Diaper.escalation2Title(baby.name)
        esc2.body  = Strings.Notifications.Diaper.escalation2Body
        esc2.sound = .default

        let severe = Self.diaperSeverelyOverdueMinutes
        let slots: [(id: String, offset: Int, content: UNMutableNotificationContent)] = [
            (ID.diaper,         minutesUntilDue,                              primary),
            (ID.diaperFollowup, minutesUntilDue + Self.followupDelayMinutes,  followup),
            (ID.diaperEsc1,     minutesUntilDue + severe,                     esc1),
            (ID.diaperEsc2,     minutesUntilDue + severe + 60,                esc2),
        ]

        await scheduleSlots(slots, allIDs: ID.diaperAll)
    }

    /// Recommended diaper-check interval by baby age. Shared with `HomeViewModel`
    /// so the urgency threshold on the status card matches the scheduler.
    static func diaperIntervalMinutes(forAgeInWeeks weeks: Int) -> Int {
        switch weeks {
        case 0..<12:  return 120   // every 2 h for newborns
        case 12..<24: return 180   // every 3 h for 3–6 months
        default:      return 240   // every 4 h for 6+ months
        }
    }

    // MARK: - Helpers

    private func schedule(id: String, content: UNMutableNotificationContent, inMinutes minutes: Int) async {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch {
            Self.logger.error(
                "Failed to schedule notification \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Schedules a set of slots whose offsets are minutes-from-now. Slots whose
    /// offset is more than `staleSkipMinutes` in the past are skipped (the
    /// parent likely intentionally deferred). Slots that are mildly overdue
    /// fire ~1 minute from now so the parent still gets a nudge. Stale or
    /// skipped slots have any prior pending request removed so they don't
    /// fire from a previous schedule cycle.
    private func scheduleSlots(
        _ slots: [(id: String, offset: Int, content: UNMutableNotificationContent)],
        allIDs: [String]
    ) async {
        // Clear all of this type's pending requests first; we'll re-add only
        // the ones whose offset is in range. Safe here because this method
        // is only invoked from `handleLogSaved` (a real log just committed),
        // never from app open / pull-to-refresh.
        center.removePendingNotificationRequests(withIdentifiers: allIDs)

        // Dedupe slots that would fire at the same minute. Happens when several
        // slots are simultaneously overdue (offset <= 0): all clamp to +1 min
        // and we'd otherwise stack identical banners. Iteration order preserves
        // the earlier (less escalated) slot, so the parent gets one prompt nudge
        // instead of a wall of pings.
        var scheduledMinutes = Set<Int>()
        for slot in slots {
            guard slot.offset > -Self.staleSkipMinutes else { continue }
            let fireMinutes = max(slot.offset, 1)
            guard scheduledMinutes.insert(fireMinutes).inserted else { continue }
            await schedule(id: slot.id, content: slot.content, inMinutes: fireMinutes)
        }
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
