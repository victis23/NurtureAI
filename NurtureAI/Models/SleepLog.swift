import Foundation
import SwiftData

@Model
final class SleepLog {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var location: SleepLocation
    var quality: SleepQuality?
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \Baby.sleepLogs) var baby: Baby?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        location: SleepLocation = .crib,
        quality: SleepQuality? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.quality = quality
        self.notes = notes
        self.createdAt = createdAt
    }

    var isOngoing: Bool { endTime == nil }

    var durationSeconds: Int? {
        guard let end = endTime else { return nil }
        return Int(end.timeIntervalSince(startTime))
    }

    var durationDisplay: String {
        guard let secs = durationSeconds else { return "Ongoing" }
        let hours = secs / 3600
        let mins = (secs % 3600) / 60
        if hours == 0 { return "\(mins)m" }
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }

    enum SleepLocation: String, Codable, CaseIterable {
        case crib = "Crib"
        case bassinet = "Bassinet"
        case parentBed = "Parent's Bed"
        case stroller = "Stroller"
        case carrier = "Carrier"
        case carSeat = "Car Seat"
        case other = "Other"
    }

    enum SleepQuality: String, Codable, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"

        var emoji: String {
            switch self {
            case .excellent: "😴"
            case .good: "🙂"
            case .fair: "😐"
            case .poor: "😟"
            }
        }
    }
}
