import Foundation

@MainActor
@Observable
final class QuickLogViewModel {

    // MARK: - Dependencies

    let timerService: ActiveTimerService

    // MARK: - Feed UI state

    var feedSide: FeedSide = .left
    var bottleML: Int?

    // MARK: - Diaper UI state

    var selectedDiaperType: DiaperType = .wet

    // MARK: - Mood UI state

    var selectedMood: MoodState = .content

    // MARK: - Confirmation

    var lastSavedLogType: LogType?
    var showSaveConfirmation: Bool = false

    // MARK: - Error

    var error: AppError?

    // MARK: - Timer state (delegated to service — single source of truth)

    var isFeedTimerRunning: Bool  { timerService.isRunning(.feed) }
    var isSleepTimerRunning: Bool { timerService.isRunning(.sleep) }
    var feedStartTime: Date?      { timerService.session(for: .feed)?.startTime }
    var sleepStartTime: Date?     { timerService.session(for: .sleep)?.startTime }

    // MARK: - Init

    init(timerService: ActiveTimerService) {
        self.timerService = timerService
    }

    // MARK: - Feed

    func startFeed() {
        timerService.start(.feed)
    }

    func stopFeed(baby: Baby) async {
        do {
            try await timerService.stop(
                .feed,
                baby: baby,
                metadata: .feed(side: feedSide, bottleML: bottleML)
            )
            feedSide = .left
            bottleML = nil
            triggerConfirmation(for: .feed)
        } catch {
            self.error = .data(error)
        }
    }

    // MARK: - Sleep

    func startSleep() {
        timerService.start(.sleep)
    }

    func stopSleep(baby: Baby) async {
        do {
            try await timerService.stop(.sleep, baby: baby, metadata: .sleep(quality: nil))
            triggerConfirmation(for: .sleep)
        } catch {
            self.error = .data(error)
        }
    }

    // MARK: - Diaper

    func logDiaper(baby: Baby) async {
        do {
            try await timerService.logInstant(
                type: .diaper,
                baby: baby,
                metadata: .diaper(type: selectedDiaperType)
            )
            triggerConfirmation(for: .diaper)
        } catch {
            self.error = .data(error)
        }
    }

    // MARK: - Mood

    func logMood(baby: Baby) async {
        do {
            try await timerService.logInstant(
                type: .mood,
                baby: baby,
                metadata: .mood(state: selectedMood, notes: nil)
            )
            triggerConfirmation(for: .mood)
        } catch {
            self.error = .data(error)
        }
    }

    // MARK: - Private

    private func triggerConfirmation(for type: LogType) {
        lastSavedLogType = type
        showSaveConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showSaveConfirmation = false
        }
    }
}
