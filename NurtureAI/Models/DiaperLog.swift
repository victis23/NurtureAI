import Foundation
import SwiftData

@Model
final class DiaperLog {
    var id: UUID
    var timestamp: Date
    var type: DiaperType
    var color: StoolColor?
    var consistency: StoolConsistency?
    var hasRash: Bool
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \Baby.diaperLogs) var baby: Baby?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: DiaperType,
        color: StoolColor? = nil,
        consistency: StoolConsistency? = nil,
        hasRash: Bool = false,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.color = color
        self.consistency = consistency
        self.hasRash = hasRash
        self.notes = notes
        self.createdAt = createdAt
    }

    enum DiaperType: String, Codable, CaseIterable {
        case wet = "Wet"
        case dirty = "Dirty"
        case both = "Both"
        case dry = "Dry"

        var emoji: String {
            switch self {
            case .wet: "💧"
            case .dirty: "💩"
            case .both: "💧💩"
            case .dry: "✓"
            }
        }
    }

    enum StoolColor: String, Codable, CaseIterable {
        case black = "Black (Meconium)"
        case darkGreen = "Dark Green"
        case yellow = "Yellow"
        case mustard = "Mustard Yellow"
        case brown = "Brown"
        case green = "Green"
        case orange = "Orange"
        case red = "Red (Blood — see doctor)"
        case white = "White/Pale (see doctor)"

        var requiresDoctorAttention: Bool {
            self == .red || self == .white
        }
    }

    enum StoolConsistency: String, Codable, CaseIterable {
        case watery = "Watery"
        case loose = "Loose"
        case seedy = "Seedy"
        case pasty = "Pasty"
        case formed = "Formed"
        case hard = "Hard"
    }
}
