import Foundation
import Observation

@Observable
@MainActor
final class FeedingLogViewModel {
    var logs: [FeedingLog] = []
    var selectedType: FeedingLog.FeedType = .breastLeft
    var amountText: String = ""
    var startTime: Date = Date()
    var endTime: Date? = nil
    var notes: String = ""
    var isTimerRunning = false
    var timerStartedAt: Date?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var showingAddSheet = false

    private var timerTask: Task<Void, Never>?
    var elapsedSeconds: Int = 0

    private let feedingRepo: any FeedingLogRepositoryProtocol

    init(feedingRepo: any FeedingLogRepositoryProtocol) {
        self.feedingRepo = feedingRepo
    }

    func loadLogs(for baby: Baby) async {
        isLoading = true
        do {
            logs = try await feedingRepo.fetchRecent(for: baby, limit: 50)
        } catch {
            errorMessage = "Failed to load feeding logs."
        }
        isLoading = false
    }

    func startTimer() {
        timerStartedAt = Date()
        startTime = Date()
        isTimerRunning = true
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let start = timerStartedAt else { break }
                elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        endTime = Date()
        isTimerRunning = false
    }

    func saveLog(for baby: Baby) async {
        isSaving = true
        errorMessage = nil
        do {
            let duration = timerStartedAt.map { Int(Date().timeIntervalSince($0)) }
            let amount = Double(amountText.replacingOccurrences(of: ",", with: "."))
            let log = FeedingLog(
                startTime: startTime,
                endTime: endTime,
                type: selectedType,
                amountMl: amount,
                durationSeconds: duration,
                notes: notes
            )
            try await feedingRepo.save(log, for: baby)
            await loadLogs(for: baby)
            resetForm()
        } catch {
            errorMessage = "Failed to save feeding log."
        }
        isSaving = false
    }

    func deleteLog(_ log: FeedingLog, for baby: Baby) async {
        do {
            try await feedingRepo.delete(log)
            await loadLogs(for: baby)
        } catch {
            errorMessage = "Failed to delete log."
        }
    }

    func resetForm() {
        selectedType = .breastLeft
        amountText = ""
        startTime = Date()
        endTime = nil
        notes = ""
        elapsedSeconds = 0
        timerStartedAt = nil
        isTimerRunning = false
        showingAddSheet = false
    }

    var elapsedDisplay: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var canSave: Bool {
        !isSaving
    }
}
