import Foundation
import SwiftData

@Model
final class GrowthMeasurement {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var notes: String
    var createdAt: Date

    @Relationship(inverse: \Baby.growthMeasurements) var baby: Baby?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        headCircumferenceCm: Double? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.headCircumferenceCm = headCircumferenceCm
        self.notes = notes
        self.createdAt = createdAt
    }
}
