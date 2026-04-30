import Foundation

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    private let logRepository: LogRepositoryProtocol
    private let patternService: PatternService
    private let notificationService: NotificationService
    let timerService: ActiveTimerService

    // MARK: - State

    var patterns: BabyPatterns?
    var isLoading: Bool = false
    var error: AppError?

    // MARK: - Timer state (delegated to service — single source of truth)

    /// The first active timed session (feed takes precedence over sleep).
    var activeTimerSession: ActiveTimerSession? {
        timerService.activeSessions[.feed] ?? timerService.activeSessions[.sleep]
    }

    /// Increments every time a log is saved via the service.
    /// HomeView observes this to trigger a pattern reload.
    var logVersion: Int { timerService.logVersion }

    // MARK: - Init

    init(
        logRepository: LogRepositoryProtocol,
        patternService: PatternService,
        timerService: ActiveTimerService,
        notificationService: NotificationService
    ) {
        self.logRepository = logRepository
        self.patternService = patternService
        self.timerService = timerService
        self.notificationService = notificationService
    }

    // MARK: - Pattern loading

    func load(baby: Baby) async {
        isLoading = true
        error = nil
        // Ensure the baby document exists in Firestore before any log writes.
        // Idempotent — self-heals babies created before the sync fix.
        await timerService.ensureBabySynced(baby)
        do {
            let since = Date().addingTimeInterval(-86400)
            let logs = try logRepository.fetchLogs(for: baby, since: since)
            let computed = patternService.analyze(logs: logs, baby: baby)
            patterns = computed
            // Permission ask is idempotent. Scheduling is intentionally NOT
            // done here — see `handleLogSaved` — to avoid resetting pending
            // notification timers every time the Home view opens or refreshes.
            await notificationService.requestPermission()
        } catch {
            self.error = .data(error)
        }
        isLoading = false
        await timerService.startListening(for: baby)
    }

    func refresh(baby: Baby) async {
        await load(baby: baby)
    }

    /// Called after a log is saved (locally or via remote sync). Recomputes
    /// patterns and reschedules notifications so the new log moves the next
    /// reminder forward. Kept separate from `load` so app-open / pull-to-refresh
    /// don't reset relative-time triggers.
    func handleLogSaved(baby: Baby) async {
        do {
            let since = Date().addingTimeInterval(-86400)
            let logs = try logRepository.fetchLogs(for: baby, since: since)
            let computed = patternService.analyze(logs: logs, baby: baby)
            patterns = computed
            await notificationService.scheduleNotifications(
                for: baby,
                patterns: computed,
                activeSessions: timerService.activeSessions
            )
        } catch {
            self.error = .data(error)
        }
    }

    // MARK: - Timer actions (delegate to service)

	func startFeed()  {
		timerService.start(.feed)
	}

	func startSleep() {
		timerService.start(.sleep)
	}

	func logDiaperFor(baby: Baby) {
		Task {
			do {
				try await timerService.logInstant(type: .diaper, baby: baby, metadata: .diaper(type: .none))
			} catch {
				self.error = .data(error)
			}
		}
	}

    /// Stops whichever session is currently active.
    /// Uses default metadata since the Home screen has no selection UI.
    func stopActiveTimer(baby: Baby) async {
        guard let session = activeTimerSession else { return }
        let metadata: LogMetadata
        switch session.type {
        case .feed:  metadata = .feed(side: .left, bottleML: nil)
        case .sleep: metadata = .sleep(quality: nil)
        default:     metadata = .none
        }
        do {
            try await timerService.stop(session.type, baby: baby, metadata: metadata)
        } catch {
            self.error = .data(error)
        }
    }

	func getValueCardStatusfor(state: LogType, isAwakeCard: Bool = false) -> String? {
		let isActive = timerService.activeSessions[state] != nil
		guard let patterns else { return nil }

		switch state {
		case .feed:
			return isActive ? Strings.Home.Status.currentlyFeeding : patterns.lastFeedMinutesAgo.map { "\($0.hmDisplay) ago" }
		case .sleep:
			if isAwakeCard {
				return isActive ? Strings.Home.Status.currentlySleeping : patterns.currentAwakeWindowMinutes.hmDisplay
			}

			let totalSleepTodayMins = patterns.totalSleepTodayMinutes
			return isActive ? Strings.Home.Status.currentlySleeping : totalSleepTodayMins.hmDisplay
		case .diaper, .mood:
			return nil
		}

	}

	// MARK: - Live (tickable) status displays
	//
	// These mirror getValueCardStatusfor but compute "Xm ago" / awake window
	// from the supplied `now`. SwiftUI's TimelineView in HomeView calls these
	// every 60 s with `context.date`, so the labels stay fresh without forcing
	// a full pattern reload. The original method above is preserved to keep
	// the existing public surface intact.

	private func minutesAgo(_ date: Date, now: Date) -> Int {
		max(0, Int(now.timeIntervalSince(date) / 60))
	}

	func lastFedDisplay(at now: Date) -> String? {
		if timerService.activeSessions[.feed] != nil {
			return Strings.Home.Status.currentlyFeeding
		}
		guard let lastFedAt = patterns?.lastFeedAt else { return nil }
		return "\(minutesAgo(lastFedAt, now: now).hmDisplay) ago"
	}

	func awakeDisplay(at now: Date) -> String? {
		if timerService.activeSessions[.sleep] != nil {
			return Strings.Home.Status.currentlySleeping
		}
		guard let lastWakeAt = patterns?.lastWakeAt else { return nil }
		return minutesAgo(lastWakeAt, now: now).hmDisplay
	}

	func sleepTodayDisplay(at now: Date) -> String? {
		guard let patterns else { return nil }
		// While a sleep session is in progress, fold its live elapsed time
		// into today's total so the card visibly grows minute-by-minute.
		var totalMinutes = patterns.totalSleepTodayMinutes
		if let active = timerService.activeSessions[.sleep] {
			let liveSecs = max(0, now.timeIntervalSince(active.startTime))
			totalMinutes += Int(liveSecs / 60)
		}
		guard patterns.lastWakeAt != nil else { return nil }
		return totalMinutes.hmDisplay
	}

	func lastDiaperDisplay(at now: Date) -> String? {
		guard let lastDiaperAt = patterns?.lastDiaperAt else { return nil }
		return "\(minutesAgo(lastDiaperAt, now: now).hmDisplay) ago"
	}

	// MARK: - Urgency
	//
	// True when the relevant window is severely overdue. Drives the red-glow
	// pulse on Home status cards. Thresholds match `NotificationService` so
	// the visual cue and the escalation pings stay in sync.

	func isFeedUrgent(at now: Date) -> Bool {
		guard let patterns else { return false }
		guard timerService.activeSessions[.feed] == nil else { return false }
		guard let lastFedAt = patterns.lastFeedAt else { return false }
		let minutesSinceFeed = minutesAgo(lastFedAt, now: now)
		let minutesUntilDue  = patterns.avgFeedIntervalMinutes - minutesSinceFeed
		return minutesUntilDue <= -NotificationService.feedSeverelyOverdueMinutes
	}

	func isAwakeUrgent(at now: Date) -> Bool {
		guard let patterns else { return false }
		guard timerService.activeSessions[.sleep] == nil else { return false }
		guard let lastWakeAt = patterns.lastWakeAt else { return false }
		let awakeMinutes    = minutesAgo(lastWakeAt, now: now)
		let minutesUntilDue = patterns.ageAppropriateMaxAwakeMinutes - awakeMinutes
		return minutesUntilDue <= -NotificationService.sleepSeverelyOverdueMinutes
	}

	func isDiaperUrgent(baby: Baby, at now: Date) -> Bool {
		guard let patterns else { return false }
		guard let lastDiaperAt = patterns.lastDiaperAt else { return false }
		let intervalMinutes = NotificationService.diaperIntervalMinutes(forAgeInWeeks: baby.ageInWeeks)
		let minutesSince    = minutesAgo(lastDiaperAt, now: now)
		let minutesUntilDue = intervalMinutes - minutesSince
		return minutesUntilDue <= -NotificationService.diaperSeverelyOverdueMinutes
	}
}
