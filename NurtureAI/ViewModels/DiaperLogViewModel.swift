import Foundation
import Observation

@Observable
final class DiaperLogViewModel {
    var logs: [DiaperLog] = []
    var selectedType: DiaperLog.DiaperType = .wet
    var selectedColor: DiaperLog.StoolColor? = nil
    var selectedConsistency: DiaperLog.StoolConsistency? = nil
    var hasRash = false
    var timestamp: Date = Date()
    var notes: String = ""
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var showingAddSheet = false
    var showingColorAlert = false
    var colorAlertMessage: String = ""

    private let diaperRepo: any DiaperLogRepositoryProtocol

    init(diaperRepo: any DiaperLogRepositoryProtocol) {
        self.diaperRepo = diaperRepo
    }

    func loadLogs(for baby: Baby) async {
        isLoading = true
        do {
            logs = try await diaperRepo.fetchRecent(for: baby, limit: 30)
        } catch {
            errorMessage = "Failed to load diaper logs."
        }
        isLoading = false
    }

    func saveLog(for baby: Baby) async {
        if let color = selectedColor, color.requiresDoctorAttention {
            colorAlertMessage = "Stool color '\(color.rawValue)' may require a doctor visit."
            showingColorAlert = true
        }

        isSaving = true
        do {
            let log = DiaperLog(
                timestamp: timestamp,
                type: selectedType,
                color: selectedColor,
                consistency: selectedConsistency,
                hasRash: hasRash,
                notes: notes
            )
            try await diaperRepo.save(log, for: baby)
            await loadLogs(for: baby)
            resetForm()
        } catch {
            errorMessage = "Failed to save diaper log."
        }
        isSaving = false
    }

    func deleteLog(_ log: DiaperLog, for baby: Baby) async {
        do {
            try await diaperRepo.delete(log)
            await loadLogs(for: baby)
        } catch {
            errorMessage = "Failed to delete log."
        }
    }

    func resetForm() {
        selectedType = .wet
        selectedColor = nil
        selectedConsistency = nil
        hasRash = false
        timestamp = Date()
        notes = ""
        showingAddSheet = false
    }

    var wetCount24h: Int {
        let cutoff = Date().addingTimeInterval(-86400)
        return logs.filter { $0.timestamp >= cutoff && ($0.type == .wet || $0.type == .both) }.count
    }

    var dirtyCount24h: Int {
        let cutoff = Date().addingTimeInterval(-86400)
        return logs.filter { $0.timestamp >= cutoff && ($0.type == .dirty || $0.type == .both) }.count
    }
}
