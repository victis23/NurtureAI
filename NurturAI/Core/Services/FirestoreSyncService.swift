import Foundation
import FirebaseFirestore

actor FirestoreSyncService {

    private let db: Firestore
    private let logRepository: LogRepositoryProtocol

    init(db: Firestore, logRepository: LogRepositoryProtocol) {
        self.db = db
        self.logRepository = logRepository
    }

    // Call on app foreground, WiFi reconnect, and every 15 min background refresh
    func syncPendingLogs(babyID: UUID, babyLogs: [BabyLog]) async throws {
        guard !babyLogs.isEmpty else { return }

        let batch = db.batch()
        for log in babyLogs {
            let ref = db
                .collection("babies").document(babyID.uuidString)
                .collection("logs").document(log.id.uuidString)
            batch.setData(log.firestorePayload, forDocument: ref, merge: true)
        }
        try await batch.commit()
    }

    // Real-time listener for caregiver-shared updates
    // Returns a cancellation token — caller must retain and cancel on deinit
    func listenForRemoteChanges(
        babyID: UUID,
        since: Date,
        onUpdate: @Sendable @escaping ([BabyLog]) -> Void
    ) -> SyncCancellable {
        let listener = db
            .collection("babies").document(babyID.uuidString)
            .collection("logs")
            .whereField("timestamp", isGreaterThan: since)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let logs = docs.compactMap { doc -> BabyLog? in
                    guard
                        let idStr = doc.data()["id"] as? String,
                        let id = UUID(uuidString: idStr),
                        let ts = (doc.data()["timestamp"] as? Timestamp)?.dateValue(),
                        let typeStr = doc.data()["type"] as? String,
                        let type = LogType(rawValue: typeStr)
                    else { return nil }
                    let log = BabyLog(id: id, timestamp: ts, type: type)
                    log.metadataJSON = doc.data()["metadataJSON"] as? String ?? "{}"
                    log.syncedToCloud = true
                    return log
                }
                Task { @MainActor in onUpdate(logs) }
            }
        return SyncCancellable { listener.remove() }
    }
}

// Minimal cancellable wrapper used until Firebase ListenerRegistration is available
final class SyncCancellable: @unchecked Sendable {
    private let cancelBlock: () -> Void
    init(_ cancel: @escaping () -> Void) { self.cancelBlock = cancel }
    func cancel() { cancelBlock() }
    deinit { cancelBlock() }
}
