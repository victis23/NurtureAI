import Foundation

@MainActor
@Observable
final class LogHistoryViewModel {
    private let logRepository: LogRepositoryProtocol

    var sections: [(date: Date, logs: [BabyLog])] = []
    var isLoading: Bool = false
    var error: AppError?

    init(logRepository: LogRepositoryProtocol) {
        self.logRepository = logRepository
    }

    func load(baby: Baby) async {
        isLoading = true
        error = nil
        do {
            let since = Date().addingTimeInterval(-30 * 86400) // last 30 days
            let logs = try logRepository.fetchLogs(for: baby, since: since)
            sections = groupByDay(logs)
        } catch {
            self.error = .data(error)
        }
        isLoading = false
    }

    func delete(_ log: BabyLog, baby: Baby) async {
        do {
            try logRepository.delete(log)
            await load(baby: baby)
        } catch {
            self.error = .data(error)
        }
    }

    private func groupByDay(_ logs: [BabyLog]) -> [(date: Date, logs: [BabyLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.timestamp)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, logs: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }
}
