import Foundation

// FirestoreSyncService — requires Firebase iOS SDK (FirebaseFirestore)
// Add the Firebase SDK via Swift Package Manager before building.
// Import: FirebaseCore, FirebaseFirestore

// Uncomment the import below once Firebase package is added:
// import FirebaseFirestore

actor FirestoreSyncService {

    // Typed as Any to allow compilation without Firebase package present
    private let db: Any
    private let logRepository: LogRepositoryProtocol

    init(db: Any, logRepository: LogRepositoryProtocol) {
        self.db = db
        self.logRepository = logRepository
    }

    // Call on app foreground, WiFi reconnect, and every 15 min background refresh
    func syncPendingLogs(babyID: UUID, babyLogs: [BabyLog]) async throws {
        guard !babyLogs.isEmpty else { return }

        // Phase 2: batch-write unsynced logs to Firestore
        // let batch = db.batch()
        // for log in babyLogs {
        //     let ref = db
        //         .collection("babies").document(babyID.uuidString)
        //         .collection("logs").document(log.id.uuidString)
        //     batch.setData(log.firestorePayload, forDocument: ref, merge: true)
        // }
        // try await batch.commit()
    }

    // Real-time listener for caregiver-shared updates
    // Returns a cancellation token — caller must retain and cancel on deinit
    func listenForRemoteChanges(
        babyID: UUID,
        since: Date,
        onUpdate: @Sendable @escaping ([BabyLog]) -> Void
    ) -> SyncCancellable {
        // Phase 2: attach Firestore snapshotListener and call onUpdate on main actor
        return SyncCancellable {}
    }
}

// Minimal cancellable wrapper used until Firebase ListenerRegistration is available
final class SyncCancellable: @unchecked Sendable {
    private let cancelBlock: () -> Void
    init(_ cancel: @escaping () -> Void) { self.cancelBlock = cancel }
    func cancel() { cancelBlock() }
    deinit { cancelBlock() }
}
