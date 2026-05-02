import Foundation

@MainActor
@Observable
final class LogHistoryViewModel {
    private let logRepository: LogRepositoryProtocol
    private let timerService: ActiveTimerService

    var sections: [(date: Date, logs: [BabyLog])] = []
    var isLoading: Bool = false
	var logVersion: Int
    var error: AppError?

    init(logRepository: LogRepositoryProtocol, timerService: ActiveTimerService) {
        self.logRepository = logRepository
        self.timerService = timerService
		self.logVersion = timerService.logVersion
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
            try await timerService.deleteLog(log, baby: baby)
            await load(baby: baby)
        } catch {
            self.error = .data(error)
        }
    }

    func update(_ log: BabyLog, baby: Baby, newTimestamp: Date, newEndTimestamp: Date?) async {
        do {
            try await timerService.updateLog(
                log,
                baby: baby,
                newTimestamp: newTimestamp,
                newEndTimestamp: newEndTimestamp
            )
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
