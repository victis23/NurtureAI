import Foundation
import SwiftData

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var weightKg: Double?
    var heightCm: Double?
    var gender: Gender
    var photoData: Data?
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var feedingLogs: [FeedingLog]
    @Relationship(deleteRule: .cascade) var sleepLogs: [SleepLog]
    @Relationship(deleteRule: .cascade) var diaperLogs: [DiaperLog]
    @Relationship(deleteRule: .cascade) var growthMeasurements: [GrowthMeasurement]
    @Relationship(deleteRule: .cascade) var conversations: [AIConversation]

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        gender: Gender = .unknown,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.gender = gender
        self.notes = notes
        self.createdAt = createdAt
        self.feedingLogs = []
        self.sleepLogs = []
        self.diaperLogs = []
        self.growthMeasurements = []
        self.conversations = []
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: Date()).day ?? 0
    }

    var ageInWeeks: Int { ageInDays / 7 }

    var ageDescription: String {
        let days = ageInDays
        if days < 14 { return "\(days) day\(days == 1 ? "" : "s") old" }
        let weeks = ageInWeeks
        if weeks < 12 { return "\(weeks) week\(weeks == 1 ? "" : "s") old" }
        let months = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        return "\(months) month\(months == 1 ? "" : "s") old"
    }

    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case unknown = "Prefer not to say"
    }
}
