import Foundation
import Observation

@Observable
final class SleepLogViewModel {
    var logs: [SleepLog] = []
    var ongoingSleep: SleepLog?
    var selectedLocation: SleepLog.SleepLocation = .crib
    var selectedQuality: SleepLog.SleepQuality? = nil
    var startTime: Date = Date()
    var endTime: Date? = nil
    var notes: String = ""
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var showingAddSheet = false
    var elapsedSeconds: Int = 0

    private var timerTask: Task<Void, Never>?
    private let sleepRepo: any SleepLogRepositoryProtocol

    init(sleepRepo: any SleepLogRepositoryProtocol) {
        self.sleepRepo = sleepRepo
    }

    func loadLogs(for baby: Baby) async {
        isLoading = true
        do {
            logs = try await sleepRepo.fetchRecent(for: baby, limit: 30)
            ongoingSleep = try await sleepRepo.fetchOngoing(for: baby)
            if let ongoing = ongoingSleep {
                startLiveTimer(from: ongoing.startTime)
            }
        } catch {
            errorMessage = "Failed to load sleep logs."
        }
        isLoading = false
    }

    func startSleep(for baby: Baby) async {
        isSaving = true
        do {
            let log = SleepLog(startTime: Date(), location: selectedLocation)
            try await sleepRepo.save(log, for: baby)
            ongoingSleep = log
            startLiveTimer(from: log.startTime)
            await loadLogs(for: baby)
        } catch {
            errorMessage = "Failed to start sleep timer."
        }
        isSaving = false
    }

    func endSleep(for baby: Baby) async {
        guard let ongoing = ongoingSleep else { return }
        isSaving = true
        do {
            ongoing.endTime = Date()
            ongoing.quality = selectedQuality
            ongoing.notes = notes
            try await sleepRepo.update(ongoing)
            ongoingSleep = nil
            stopLiveTimer()
            await loadLogs(for: baby)
            resetForm()
        } catch {
            errorMessage = "Failed to end sleep."
        }
        isSaving = false
    }

    func saveManualLog(for baby: Baby) async {
        isSaving = true
        do {
            let log = SleepLog(
                startTime: startTime,
                endTime: endTime,
                location: selectedLocation,
                quality: selectedQuality,
                notes: notes
            )
            try await sleepRepo.save(log, for: baby)
            await loadLogs(for: baby)
            resetForm()
        } catch {
            errorMessage = "Failed to save sleep log."
        }
        isSaving = false
    }

    func deleteLog(_ log: SleepLog, for baby: Baby) async {
        do {
            try await sleepRepo.delete(log)
            await loadLogs(for: baby)
        } catch {
            errorMessage = "Failed to delete log."
        }
    }

    private func startLiveTimer(from start: Date) {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                elapsedSeconds = Int(Date().timeIntervalSince(start))
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func stopLiveTimer() {
        timerTask?.cancel()
        timerTask = nil
        elapsedSeconds = 0
    }

    func resetForm() {
        selectedLocation = .crib
        selectedQuality = nil
        startTime = Date()
        endTime = nil
        notes = ""
        showingAddSheet = false
    }

    var elapsedDisplay: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    var isSleeping: Bool { ongoingSleep != nil }
}
