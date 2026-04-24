import Foundation
import FirebaseAuth
import FirebaseFirestore

actor FirestoreSyncService {

    private let db: Firestore
    private let logRepository: LogRepositoryProtocol

    init(db: Firestore, logRepository: LogRepositoryProtocol) {
        self.db = db
        self.logRepository = logRepository
    }

    // Sendable value type used to carry baby data across the actor boundary on restore.
    struct BabyRestoreData: Sendable {
        let id: UUID
        let name: String
        let birthDate: Date
        let feedingMethod: FeedingMethod
        let caregiverFirebaseUIDs: [String]
        let createdAt: Date
    }

    // Queries Firestore for a baby document that lists uid in caregiverFirebaseUIDs.
    // Returns nil if no existing account is found (genuine new user).
    func fetchBabyForRestore(uid: String) async throws -> BabyRestoreData? {
        let snapshot = try await db
            .collection("babies")
            .whereField("caregiverFirebaseUIDs", arrayContains: uid)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        let data = doc.data()

        guard
            let idStr           = data["id"] as? String,
            let id              = UUID(uuidString: idStr),
            let name            = data["name"] as? String,
            let birthDate       = (data["birthDate"] as? Timestamp)?.dateValue(),
            let methodStr       = data["feedingMethod"] as? String,
            let feedingMethod   = FeedingMethod(rawValue: methodStr)
        else { return nil }

        let caregiverUIDs = data["caregiverFirebaseUIDs"] as? [String] ?? [uid]
        let createdAt     = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now

        return BabyRestoreData(
            id: id,
            name: name,
            birthDate: birthDate,
            feedingMethod: feedingMethod,
            caregiverFirebaseUIDs: caregiverUIDs,
            createdAt: createdAt
        )
    }

    // Creates or updates the baby document in Firestore.
    // Idempotent (merge: true) — safe to call on every app launch.
    // Automatically includes the current user's UID in caregiverFirebaseUIDs
    // so existing babies created before the sync fix are self-healed.
    func syncBaby(_ baby: Baby) async throws {
        var uids = baby.caregiverFirebaseUIDs
        if let currentUID = Auth.auth().currentUser?.uid, !uids.contains(currentUID) {
            uids.append(currentUID)
        }
        let data: [String: Any] = [
            "id":                    baby.id.uuidString,
            "name":                  baby.name,
            "birthDate":             Timestamp(date: baby.birthDate),
            "feedingMethod":         baby.feedingMethod.rawValue,
            "caregiverFirebaseUIDs": uids,
            "createdAt":             Timestamp(date: baby.createdAt)
        ]
        try await db
            .collection("babies")
            .document(baby.id.uuidString)
            .setData(data, merge: true)
    }

    // Removes a single log document from Firestore.
    func deleteLog(babyID: UUID, logID: UUID) async throws {
        try await db
            .collection("babies").document(babyID.uuidString)
            .collection("logs").document(logID.uuidString)
            .delete()
    }

    // Removes baby + entire logs sub-collection from Firestore.
    // Firestore does not cascade-delete sub-collections, so logs must be deleted first.
    // Batches deletes in chunks of 500 to respect Firestore's batch limit.
    func deleteBaby(babyID: UUID) async throws {
        let babyRef = db.collection("babies").document(babyID.uuidString)
        let logsRef = babyRef.collection("logs")

        // Page through logs and batch-delete until none remain.
        while true {
            let snapshot = try await logsRef.limit(to: 500).getDocuments()
            if snapshot.documents.isEmpty { break }

            let batch = db.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()

            if snapshot.documents.count < 500 { break }
        }

        try await babyRef.delete()
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

    // Real-time listener for caregiver-shared updates.
    // onUpdate — logs that were added or modified remotely (upsert into SwiftData).
    // onDelete — UUIDs of logs that were removed remotely (delete from SwiftData).
    // Returns a cancellation token — caller must retain and cancel on deinit.
    func listenForRemoteChanges(
        babyID: UUID,
        since: Date,
        onUpdate: @MainActor @Sendable @escaping ([BabyLog]) -> Void,
        onDelete: @MainActor @Sendable @escaping ([UUID]) -> Void
    ) -> SyncCancellable {
        let listener = db
            .collection("babies").document(babyID.uuidString)
            .collection("logs")
            .whereField("timestamp", isGreaterThan: since)
            .addSnapshotListener { snapshot, _ in
                guard let changes = snapshot?.documentChanges else { return }

                var upserted: [BabyLog] = []
                var deletedIDs: [UUID] = []

                for change in changes {
                    let data = change.document.data()
                    switch change.type {
                    case .added, .modified:
                        guard
                            let idStr  = data["id"] as? String,
                            let id     = UUID(uuidString: idStr),
                            let ts     = (data["timestamp"] as? Timestamp)?.dateValue(),
                            let typeStr = data["type"] as? String,
                            let type   = LogType(rawValue: typeStr)
                        else { continue }
                        let log = BabyLog(id: id, timestamp: ts, type: type)
                        log.endTimestamp  = (data["endTimestamp"] as? Timestamp)?.dateValue()
                        log.metadataJSON  = data["metadataJSON"] as? String ?? "{}"
                        log.syncedToCloud = true
                        upserted.append(log)
                    case .removed:
                        guard
                            let idStr = data["id"] as? String,
                            let id    = UUID(uuidString: idStr)
                        else { continue }
                        deletedIDs.append(id)
                    @unknown default:
                        break
                    }
                }

                if !upserted.isEmpty   { Task { @MainActor in onUpdate(upserted) } }
                if !deletedIDs.isEmpty { Task { @MainActor in onDelete(deletedIDs) } }
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
