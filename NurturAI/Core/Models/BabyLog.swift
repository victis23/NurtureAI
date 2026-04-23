import Foundation
import SwiftData

@Model
final class BabyLog {
    var id: UUID
    var timestamp: Date
    var endTimestamp: Date?
    var type: LogType
    var metadataJSON: String
    var caregiverUID: String?
    var syncedToCloud: Bool
    var baby: Baby?

    var durationSeconds: Int? {
        guard let end = endTimestamp else { return nil }
        return Int(end.timeIntervalSince(timestamp))
    }

    var metadata: LogMetadata {
        get {
            guard let data = metadataJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(LogMetadata.self, from: data)
            else { return .none }
            return decoded
        }
        set {
            metadataJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "{}"
        }
    }

    var firestorePayload: [String: Any] {
        var payload: [String: Any] = [
            "id": id.uuidString,
            "timestamp": timestamp,
            "type": type.rawValue,
            "metadataJSON": metadataJSON,
            "syncedToCloud": true
        ]
        if let end = endTimestamp { payload["endTimestamp"] = end }
        if let uid = caregiverUID { payload["caregiverUID"] = uid }
        return payload
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        endTimestamp: Date? = nil,
        type: LogType,
        metadataJSON: String = "{}",
        caregiverUID: String? = nil,
        syncedToCloud: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.endTimestamp = endTimestamp
        self.type = type
        self.metadataJSON = metadataJSON
        self.caregiverUID = caregiverUID
        self.syncedToCloud = syncedToCloud
    }
}
