import Foundation

// MARK: - Session Model

/// Represents an in-progress timed log session.
/// Stored by LogType key so any future log type gets timer support
/// without changing the service interface.
///
/// Codable so the service can persist running sessions to UserDefaults
/// and restore them on cold launch — see `ActiveTimerService.persistActiveSessions`.
/// `startTime` is an absolute Date, so `elapsed` keeps computing the
/// correct duration even if the app was killed for hours in between.
struct ActiveTimerSession: Codable {
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

    /// Ensures the baby document exists in Firestore with the correct caregiver UID.
    /// Call on app launch / every load — idempotent, non-fatal.
    func ensureBabySynced(_ baby: Baby) async

    /// Deletes a log from SwiftData and Firestore, and increments logVersion.
    func deleteLog(_ log: BabyLog, baby: Baby) async throws

    /// Starts the real-time Firestore listener for remote log changes.
    /// No-op if already listening — safe to call on every load.
    func startListening(for baby: Baby) async
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
    private var remoteListener: SyncCancellable?
    private var observedBaby: Baby?

    init(
        logRepository: LogRepositoryProtocol,
        syncService: FirestoreSyncService,
        contextBuilder: BabyContextBuilder
    ) {
        self.logRepository = logRepository
        self.syncService = syncService
        self.contextBuilder = contextBuilder
        // Rehydrate any timer that was running when the app was killed.
        // Safe to do at the end of init — purely local read, no I/O.
        restoreActiveSessions()
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
        persistActiveSessions()
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
        persistActiveSessions()
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

    // MARK: - Delete

    func deleteLog(_ log: BabyLog, baby: Baby) async throws {
        // Capture the ID before deletion — accessing the model after SwiftData
        // removes it from the context is unsafe.
        let logID = log.id
        try logRepository.delete(log)
        logVersion += 1
        Task {
            do {
                try await syncService.deleteLog(babyID: baby.id, logID: logID)
            } catch {
                // Non-fatal — doc may already be absent or user is offline.
                // SwiftData is already consistent; Firestore will drift at worst.
            }
        }
    }

    // MARK: - Remote Listener

    func startListening(for baby: Baby) async {
        // Guard ensures we only attach one listener per app session.
        guard remoteListener == nil else { return }
        // Store on self (@MainActor) — never captured directly in a @Sendable closure.
        observedBaby = baby
        let since = Date().addingTimeInterval(-30 * 86400) // mirror history window
        remoteListener = await syncService.listenForRemoteChanges(
            babyID: baby.id,
            since: since,
            onUpdate: { [weak self] logs in self?.handleRemoteUpserts(logs) },
            onDelete: { [weak self] ids  in self?.handleRemoteDeletes(ids)  }
        )
    }

    private func handleRemoteUpserts(_ logs: [BabyLog]) {
        guard let baby = observedBaby else { return }
        var changed = false
        for log in logs {
            do {
                if let existing = try logRepository.fetchLog(id: log.id) {
                    // Log already in SwiftData — apply remote field updates.
                    existing.metadataJSON  = log.metadataJSON
                    existing.endTimestamp  = log.endTimestamp
                    existing.syncedToCloud = true
                    try logRepository.saveChanges()
                } else {
                    // New log from another caregiver — link to baby and insert.
                    log.baby = baby
                    try logRepository.save(log)
                }
                changed = true
            } catch {
                // Non-fatal — local state stays consistent
            }
        }
        if changed { logVersion += 1 }
    }

    private func handleRemoteDeletes(_ ids: [UUID]) {
        var changed = false
        for id in ids {
            do {
                if let log = try logRepository.fetchLog(id: id) {
                    try logRepository.delete(log)
                    changed = true
                }
            } catch {
                // Non-fatal — log may already be absent locally
            }
        }
        if changed { logVersion += 1 }
    }

    // MARK: - Baby Sync

    func ensureBabySynced(_ baby: Baby) async {
        do {
            try await syncService.syncBaby(baby)
        } catch {
            // Non-fatal — logs will still save locally and retry on next launch
        }
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

    // MARK: - Active session persistence
    //
    // The full set of running sessions is mirrored to UserDefaults under a
    // single key. We encode an array of sessions (not a [LogType: …] dict)
    // because Swift's JSON encoder treats string-enum-keyed dictionaries
    // inconsistently across versions; an array round-trips cleanly and the
    // dictionary is rebuilt by `type` on restore. State changes are rare
    // (only on start / stop), so writing the whole blob each time is fine.

    private static let storageKey = "nurtur.activeTimerSessions.v1"

    private func persistActiveSessions() {
        let defaults = UserDefaults.standard
        let sessions = Array(activeSessions.values)
        guard !sessions.isEmpty else {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }
        do {
            let data = try JSONEncoder().encode(sessions)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            // Non-fatal — worst case the user loses timer continuity if
            // the app is killed before the next successful persist.
        }
    }

    private func restoreActiveSessions() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        do {
            let sessions = try JSONDecoder().decode([ActiveTimerSession].self, from: data)
            var dict: [LogType: ActiveTimerSession] = [:]
            for session in sessions { dict[session.type] = session }
            activeSessions = dict
        } catch {
            // Corrupt blob — clear it so we don't keep failing every launch.
            defaults.removeObject(forKey: Self.storageKey)
        }
    }
}
