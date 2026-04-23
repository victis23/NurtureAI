import Foundation
import SwiftData

@MainActor
@Observable
final class QuickLogViewModel {
    private let logRepository: LogRepositoryProtocol
    private let contextBuilder: BabyContextBuilder

    // Feed
    var feedStartTime: Date?
    var feedSide: FeedSide = .left
    var bottleML: Int?
    var isFeedTimerRunning: Bool { feedStartTime != nil }

    // Sleep
    var sleepStartTime: Date?
    var isSleepTimerRunning: Bool { sleepStartTime != nil }

    // Diaper
    var selectedDiaperType: DiaperType = .wet

    // Mood
    var selectedMood: MoodState = .content

    // Confirmation
    var lastSavedLogType: LogType?
    var showSaveConfirmation: Bool = false

    var error: AppError?

    init(logRepository: LogRepositoryProtocol, contextBuilder: BabyContextBuilder) {
        self.logRepository = logRepository
        self.contextBuilder = contextBuilder
    }

    func startFeed() {
        feedStartTime = .now
    }

    func startSleep() {
        sleepStartTime = .now
    }

    func stopFeed(baby: Baby) async {
        guard let start = feedStartTime else { return }
        let log = BabyLog(
            timestamp: start,
            endTimestamp: .now,
            type: .feed
        )
        log.metadata = .feed(side: feedSide, bottleML: bottleML)
        log.baby = baby
        do {
            try logRepository.save(log)
            contextBuilder.invalidate()
        } catch {
            self.error = .data(error)
        }
        feedStartTime = nil
        feedSide = .left
        bottleML = nil
        triggerConfirmation(for: .feed)
    }

    func stopSleep(baby: Baby) async {
        guard let start = sleepStartTime else { return }
        let log = BabyLog(
            timestamp: start,
            endTimestamp: .now,
            type: .sleep
        )
        log.metadata = .sleep(quality: nil)
        log.baby = baby
        do {
            try logRepository.save(log)
            contextBuilder.invalidate()
        } catch {
            self.error = .data(error)
        }
        sleepStartTime = nil
        triggerConfirmation(for: .sleep)
    }

    func logDiaper(baby: Baby) async {
        let log = BabyLog(timestamp: .now, type: .diaper)
        log.metadata = .diaper(type: selectedDiaperType)
        log.baby = baby
        do {
            try logRepository.save(log)
            contextBuilder.invalidate()
        } catch {
            self.error = .data(error)
        }
        triggerConfirmation(for: .diaper)
    }

    func logMood(baby: Baby) async {
        let log = BabyLog(timestamp: .now, type: .mood)
        log.metadata = .mood(state: selectedMood, notes: nil)
        log.baby = baby
        do {
            try logRepository.save(log)
            contextBuilder.invalidate()
        } catch {
            self.error = .data(error)
        }
        triggerConfirmation(for: .mood)
    }

    private func triggerConfirmation(for type: LogType) {
        lastSavedLogType = type
        showSaveConfirmation = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showSaveConfirmation = false
        }
    }
}
