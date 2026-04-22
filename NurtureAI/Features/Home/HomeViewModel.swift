import Foundation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    private let logRepository: LogRepositoryProtocol
    private let patternService: PatternService
    private let contextBuilder: BabyContextBuilder

    var patterns: BabyPatterns?
    var isLoading: Bool = false
    var error: AppError?
    var activeTimer: ActiveTimer?
    private var timerTask: Task<Void, Never>?

    struct ActiveTimer {
        let type: LogType
        let startedAt: Date
        var elapsed: TimeInterval { Date().timeIntervalSince(startedAt) }
    }

    init(logRepository: LogRepositoryProtocol, patternService: PatternService, contextBuilder: BabyContextBuilder) {
        self.logRepository = logRepository
        self.patternService = patternService
        self.contextBuilder = contextBuilder
    }

    func load(baby: Baby) async {
        isLoading = true
        error = nil
        do {
            let since = Date().addingTimeInterval(-86400)
            let logs = try logRepository.fetchLogs(for: baby, since: since)
            patterns = patternService.analyze(logs: logs, baby: baby)
        } catch {
            self.error = .data(error)
        }
        isLoading = false
    }

    func refresh(baby: Baby) async {
        await load(baby: baby)
    }

    func startTimer(type: LogType) {
        activeTimer = ActiveTimer(type: type, startedAt: .now)
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                // Trigger UI update by reassigning activeTimer
                if let current = activeTimer {
                    activeTimer = current
                }
            }
        }
    }

    func stopTimer(baby: Baby, context: ModelContext) async {
        timerTask?.cancel()
        timerTask = nil
        guard let timer = activeTimer else { return }
        activeTimer = nil

        let log = BabyLog(
            timestamp: timer.startedAt,
            endTimestamp: .now,
            type: timer.type
        )
        switch timer.type {
        case .feed: log.metadata = .feed(side: .left, bottleML: nil)
        case .sleep: log.metadata = .sleep(quality: nil)
        default: break
        }
        log.baby = baby

        do {
            try logRepository.save(log)
            contextBuilder.invalidate()
            await load(baby: baby)
        } catch {
            self.error = .data(error)
        }
    }
}
