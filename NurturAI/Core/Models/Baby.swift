import Foundation
import SwiftData

@Model
final class Baby {
    var id: UUID
    var name: String
    var birthDate: Date
    var feedingMethod: FeedingMethod
    var birthWeightGrams: Int
    var currentWeightGrams: Int
    var sensitivities: [String]
    var caregiverFirebaseUIDs: [String]
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var logs: [BabyLog]

    @Relationship(deleteRule: .cascade)
    var insights: [AIInsight]

    var ageInWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: birthDate, to: .now).weekOfYear ?? 0
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
    }

    var displayAge: String {
        let weeks = ageInWeeks
        if weeks < 16 { return "\(weeks) weeks old" }
        let months = weeks / 4
        return "\(months) months old"
    }

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        feedingMethod: FeedingMethod,
        birthWeightGrams: Int = 0,
        currentWeightGrams: Int = 0,
        sensitivities: [String] = [],
        caregiverFirebaseUIDs: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.feedingMethod = feedingMethod
        self.birthWeightGrams = birthWeightGrams
        self.currentWeightGrams = currentWeightGrams
        self.sensitivities = sensitivities
        self.caregiverFirebaseUIDs = caregiverFirebaseUIDs
        self.createdAt = createdAt
        self.logs = []
        self.insights = []
    }
}
