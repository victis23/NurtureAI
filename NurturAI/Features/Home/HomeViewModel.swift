import Foundation

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    private let logRepository: LogRepositoryProtocol
    private let patternService: PatternService
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
        timerService: ActiveTimerService
    ) {
        self.logRepository = logRepository
        self.patternService = patternService
        self.timerService = timerService
    }

    // MARK: - Pattern loading

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

    // MARK: - Timer actions (delegate to service)

    func startFeed()  { timerService.start(.feed) }
    func startSleep() { timerService.start(.sleep) }

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
}
