import Foundation
import SwiftData

@Model
final class FeedingLog {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var type: FeedType
    var amountMl: Double?
    var durationSeconds: Int?
    var side: BreastSide?
    var foodName: String?
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \Baby.feedingLogs) var baby: Baby?

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        type: FeedType,
        amountMl: Double? = nil,
        durationSeconds: Int? = nil,
        side: BreastSide? = nil,
        foodName: String? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.amountMl = amountMl
        self.durationSeconds = durationSeconds
        self.side = side
        self.foodName = foodName
        self.notes = notes
        self.createdAt = createdAt
    }

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var durationDisplay: String {
        guard let secs = durationSeconds ?? duration.map(Int.init) else { return "—" }
        let mins = secs / 60
        let remaining = secs % 60
        if mins == 0 { return "\(remaining)s" }
        return remaining == 0 ? "\(mins)m" : "\(mins)m \(remaining)s"
    }

    enum FeedType: String, Codable, CaseIterable {
        case breastLeft = "Breast (Left)"
        case breastRight = "Breast (Right)"
        case breastBoth = "Breast (Both)"
        case bottle = "Bottle"
        case formula = "Formula"
        case solid = "Solid Food"
        case pumped = "Pumped Milk"

        var isBreast: Bool {
            [.breastLeft, .breastRight, .breastBoth, .pumped].contains(self)
        }
        var isBottle: Bool { self == .bottle || self == .formula || self == .pumped }
        var isSolid: Bool { self == .solid }
    }

    enum BreastSide: String, Codable, CaseIterable {
        case left = "Left"
        case right = "Right"
        case both = "Both"
    }
}
