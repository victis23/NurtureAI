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
        let isFirstChild: Bool
        let birthWeightGrams: Int
        let currentWeightGrams: Int
        let familySupport: FamilySupport
        let overwhelmLevel: OverwhelmLevel
        let emotionalWellbeing: EmotionalWellbeing
        let householdType: HouseholdType
        let desiredFeatures: [String]
        let internetUsageFrequency: InternetUsageFrequency
        let appDiscoverySource: AppDiscoverySource
        let teethingStatus: TeethingStatus
        let solidFoodStatus: SolidFoodStatus
        let pediatricianVisitFrequency: PediatricianVisitFrequency
        let feedingFrequency: FeedingFrequency
        let childcareChallenges: [String]
        let bathingFrequency: BathingFrequency
        let aiUsageHistory: AIUsageHistory
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
        let isFirstChild  = data["isFirstChild"] as? Bool ?? true

        // Extended onboarding fields. All default to the same values used in Baby.init,
        // so legacy Firestore documents that predate these fields restore cleanly.
        let birthWeightGrams   = data["birthWeightGrams"] as? Int ?? 0
        let currentWeightGrams = data["currentWeightGrams"] as? Int ?? 0
        let familySupport       = (data["familySupport"] as? String).flatMap(FamilySupport.init(rawValue:)) ?? .preferNotToSay
        let overwhelmLevel      = (data["overwhelmLevel"] as? String).flatMap(OverwhelmLevel.init(rawValue:)) ?? .preferNotToSay
        let emotionalWellbeing  = (data["emotionalWellbeing"] as? String).flatMap(EmotionalWellbeing.init(rawValue:)) ?? .preferNotToSay
        let householdType       = (data["householdType"] as? String).flatMap(HouseholdType.init(rawValue:)) ?? .preferNotToSay
        let desiredFeatures     = data["desiredFeatures"] as? [String] ?? []
        let internetUsage       = (data["internetUsageFrequency"] as? String).flatMap(InternetUsageFrequency.init(rawValue:)) ?? .sometimes
        let appDiscovery        = (data["appDiscoverySource"] as? String).flatMap(AppDiscoverySource.init(rawValue:)) ?? .other
        let teething            = (data["teethingStatus"] as? String).flatMap(TeethingStatus.init(rawValue:)) ?? .unsure
        let solids              = (data["solidFoodStatus"] as? String).flatMap(SolidFoodStatus.init(rawValue:)) ?? .notYet
        let pediatricianVisits  = (data["pediatricianVisitFrequency"] as? String).flatMap(PediatricianVisitFrequency.init(rawValue:)) ?? .everyFewMonths
        let feedingFreq         = (data["feedingFrequency"] as? String).flatMap(FeedingFrequency.init(rawValue:)) ?? .onDemand
        let challenges          = data["childcareChallenges"] as? [String] ?? []
        let bathingFreq         = (data["bathingFrequency"] as? String).flatMap(BathingFrequency.init(rawValue:)) ?? .everyFewDays
        let aiHistory           = (data["aiUsageHistory"] as? String).flatMap(AIUsageHistory.init(rawValue:)) ?? .never

        return BabyRestoreData(
            id: id,
            name: name,
            birthDate: birthDate,
            feedingMethod: feedingMethod,
            caregiverFirebaseUIDs: caregiverUIDs,
            createdAt: createdAt,
            isFirstChild: isFirstChild,
            birthWeightGrams: birthWeightGrams,
            currentWeightGrams: currentWeightGrams,
            familySupport: familySupport,
            overwhelmLevel: overwhelmLevel,
            emotionalWellbeing: emotionalWellbeing,
            householdType: householdType,
            desiredFeatures: desiredFeatures,
            internetUsageFrequency: internetUsage,
            appDiscoverySource: appDiscovery,
            teethingStatus: teething,
            solidFoodStatus: solids,
            pediatricianVisitFrequency: pediatricianVisits,
            feedingFrequency: feedingFreq,
            childcareChallenges: challenges,
            bathingFrequency: bathingFreq,
            aiUsageHistory: aiHistory
        )
    }

    // Creates or updates the baby document in Firestore.
    // Idempotent (merge: true) — safe to call on every app launch.
    // Automatically includes the current user's UID in caregiverFirebaseUIDs
    // so existing babies created before the sync fix are self-healed.
    func syncBaby(_ baby: Baby) async throws {
        // Bug #2 fix: a missing UID used to silently no-op the self-heal step,
        // which broke the restore flow on accounts created before caregiver UIDs
        // were tracked. Fail loudly instead so the caller can re-auth.
        guard let currentUID = Auth.auth().currentUser?.uid else {
            throw AuthError.notSignedIn
        }
        var uids = baby.caregiverFirebaseUIDs
        if !uids.contains(currentUID) {
            uids.append(currentUID)
        }
        let data: [String: Any] = [
            "id":                         baby.id.uuidString,
            "name":                       baby.name,
            "birthDate":                  Timestamp(date: baby.birthDate),
            "feedingMethod":              baby.feedingMethod.rawValue,
            "caregiverFirebaseUIDs":      uids,
            "createdAt":                  Timestamp(date: baby.createdAt),
            "isFirstChild":               baby.isFirstChild,
            "birthWeightGrams":           baby.birthWeightGrams,
            "currentWeightGrams":         baby.currentWeightGrams,
            "familySupport":              baby.familySupport.rawValue,
            "overwhelmLevel":             baby.overwhelmLevel.rawValue,
            "emotionalWellbeing":         baby.emotionalWellbeing.rawValue,
            "householdType":              baby.householdType.rawValue,
            "desiredFeatures":            baby.desiredFeatures,
            "internetUsageFrequency":     baby.internetUsageFrequency.rawValue,
            "appDiscoverySource":         baby.appDiscoverySource.rawValue,
            "teethingStatus":             baby.teethingStatus.rawValue,
            "solidFoodStatus":            baby.solidFoodStatus.rawValue,
            "pediatricianVisitFrequency": baby.pediatricianVisitFrequency.rawValue,
            "feedingFrequency":           baby.feedingFrequency.rawValue,
            "childcareChallenges":        baby.childcareChallenges,
            "bathingFrequency":           baby.bathingFrequency.rawValue,
            "aiUsageHistory":             baby.aiUsageHistory.rawValue
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

    // Call on app foreground, WiFi reconnect, and every 15 min background refresh.
    // Bug #1 fix: Firestore batches cap at 500 ops, so chunk the pending logs
    // (mirrors deleteBaby above). Previously a single batch was used and any
    // backlog &gt; 500 logs would throw and abort the whole sync.
    func syncPendingLogs(babyID: UUID, babyLogs: [BabyLog]) async throws {
        guard !babyLogs.isEmpty else { return }

        let chunkSize = 500
        for chunk in stride(from: 0, to: babyLogs.count, by: chunkSize) {
            let end = min(chunk + chunkSize, babyLogs.count)
            let batch = db.batch()
            for log in babyLogs[chunk..<end] {
                let ref = db
                    .collection("babies").document(babyID.uuidString)
                    .collection("logs").document(log.id.uuidString)
                batch.setData(log.firestorePayload, forDocument: ref, merge: true)
            }
            try await batch.commit()
        }
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
