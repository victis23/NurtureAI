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
            // Request permission once (no-op if already granted/denied),
            // then reschedule notifications based on the latest patterns.
            await notificationService.requestPermission()
            await notificationService.scheduleNotifications(
                for: baby,
                patterns: computed,
                activeSessions: timerService.activeSessions
            )
        } catch {
            self.error = .data(error)
        }
        isLoading = false
        await timerService.startListening(for: baby)
    }

    func refresh(baby: Baby) async {
        await load(baby: baby)
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
			return isActive ? Strings.Home.Status.currentlyFeeding : patterns.lastFeedMinutesAgo.map { "\($0)m ago" }
		case .sleep:
			if isAwakeCard {
				return isActive ? Strings.Home.Status.currentlySleeping : "\(patterns.currentAwakeWindowMinutes)m"
			}

			let totalSleepTodayMins = patterns.totalSleepTodayMinutes
			return isActive ? Strings.Home.Status.currentlySleeping : "\(totalSleepTodayMins / 60)h \(totalSleepTodayMins % 60)m"
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
		return "\(minutesAgo(lastFedAt, now: now))m ago"
	}

	func awakeDisplay(at now: Date) -> String? {
		if timerService.activeSessions[.sleep] != nil {
			return Strings.Home.Status.currentlySleeping
		}
		guard let lastWakeAt = patterns?.lastWakeAt else { return "0m" }
		return "\(minutesAgo(lastWakeAt, now: now))m"
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
		return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
	}

	func lastDiaperDisplay(at now: Date) -> String? {
		guard let lastDiaperAt = patterns?.lastDiaperAt else { return nil }
		return "\(minutesAgo(lastDiaperAt, now: now))m ago"
	}
}
