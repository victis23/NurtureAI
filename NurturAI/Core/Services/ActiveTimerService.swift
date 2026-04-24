import Foundation

// MARK: - Session Model

/// Represents an in-progress timed log session.
/// Stored by LogType key so any future log type gets timer support
/// without changing the service interface.
struct ActiveTimerSession {
    let type: LogType
    let startTime: Date
    var elapsed: TimeInterval { Date().timeIntervalSince(startTime) }
}

// MARK: - Protocol

/// Contract for the active timer service.
/// Depends on LogRepositoryProtocol (not concretions) — DIP compliant.
/// All methods are @MainActor — safe to call from any VM or View on the main actor.
@MainActor
protocol ActiveTimerServiceProtocol: AnyObject {
    /// All currently running sessions, keyed by LogType.
    var activeSessions: [LogType: ActiveTimerSession] { get }

    /// Increments every time a log is saved (timed or instant).
    /// Observers watch this to trigger UI refreshes.
    var logVersion: Int { get }

    func isRunning(_ type: LogType) -> Bool
    func session(for type: LogType) -> ActiveTimerSession?

    /// Starts a new session. No-op if one is already running for this type.
    func start(_ type: LogType)

    /// Stops a running session, saves the log with the supplied metadata, and syncs.
    func stop(_ type: LogType, baby: Baby, metadata: LogMetadata) async throws

    /// Saves an instant (non-timed) log and syncs. Used for Diaper, Mood, etc.
    func logInstant(type: LogType, baby: Baby, metadata: LogMetadata) async throws
}

// MARK: - Implementation

/// Concrete, @Observable implementation injected via AppContainer.
/// Stored as the concrete type in VMs so @Observable tracking works correctly.
@MainActor
@Observable
final class ActiveTimerService: ActiveTimerServiceProtocol {

    private(set) var activeSessions: [LogType: ActiveTimerSession] = [:]
    private(set) var logVersion: Int = 0

    private let logRepository: LogRepositoryProtocol
    private let syncService: FirestoreSyncService
    private let contextBuilder: BabyContextBuilder

    init(
        logRepository: LogRepositoryProtocol,
        syncService: FirestoreSyncService,
        contextBuilder: BabyContextBuilder
    ) {
        self.logRepository = logRepository
        self.syncService = syncService
        self.contextBuilder = contextBuilder
    }

    // MARK: - Queries

    func isRunning(_ type: LogType) -> Bool {
        activeSessions[type] != nil
    }

    func session(for type: LogType) -> ActiveTimerSession? {
        activeSessions[type]
    }

    // MARK: - Timer Lifecycle

    func start(_ type: LogType) {
        guard activeSessions[type] == nil else { return }
        activeSessions[type] = ActiveTimerSession(type: type, startTime: .now)
    }

    func stop(_ type: LogType, baby: Baby, metadata: LogMetadata) async throws {
        guard let session = activeSessions[type] else { return }

        let log = BabyLog(
            timestamp: session.startTime,
            endTimestamp: .now,
            type: type
        )
        log.metadata = metadata
        log.baby = baby

        try logRepository.save(log)
        activeSessions[type] = nil
        contextBuilder.invalidate()
        logVersion += 1
        syncAfterSave(baby: baby)
    }

    // MARK: - Instant Logging

    func logInstant(type: LogType, baby: Baby, metadata: LogMetadata) async throws {
        let log = BabyLog(timestamp: .now, type: type)
        log.metadata = metadata
        log.baby = baby

        try logRepository.save(log)
        contextBuilder.invalidate()
        logVersion += 1
        syncAfterSave(baby: baby)
    }

    // MARK: - Private

    private func syncAfterSave(baby: Baby) {
        Task {
            do {
                let unsynced = try logRepository.fetchUnsynced(for: baby)
                guard !unsynced.isEmpty else { return }
                try await syncService.syncPendingLogs(babyID: baby.id, babyLogs: unsynced)
                try logRepository.markSynced(unsynced)
            } catch {
                // Non-fatal — will retry on next save or app foreground
            }
        }
    }
}
