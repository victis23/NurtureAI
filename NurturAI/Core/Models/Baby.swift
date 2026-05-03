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
	var isFirstChild: Bool

	// Extended onboarding answers
	var familySupport: FamilySupport
	var overwhelmLevel: OverwhelmLevel
	var emotionalWellbeing: EmotionalWellbeing
	var householdType: HouseholdType
	var desiredFeatures: [String]      // raw values of DesiredFeature
	var internetUsageFrequency: InternetUsageFrequency
	var appDiscoverySource: AppDiscoverySource
	var teethingStatus: TeethingStatus
	var solidFoodStatus: SolidFoodStatus
	var pediatricianVisitFrequency: PediatricianVisitFrequency
	var feedingFrequency: FeedingFrequency
	var childcareChallenges: [String]  // raw values of ChildcareChallenge
	var bathingFrequency: BathingFrequency
	var aiUsageHistory: AIUsageHistory

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
        createdAt: Date = .now,
		isFirstChild: Bool = true,
		familySupport: FamilySupport = .preferNotToSay,
		overwhelmLevel: OverwhelmLevel = .preferNotToSay,
		emotionalWellbeing: EmotionalWellbeing = .preferNotToSay,
		householdType: HouseholdType = .preferNotToSay,
		desiredFeatures: [String] = [],
		internetUsageFrequency: InternetUsageFrequency = .sometimes,
		appDiscoverySource: AppDiscoverySource = .other,
		teethingStatus: TeethingStatus = .unsure,
		solidFoodStatus: SolidFoodStatus = .notYet,
		pediatricianVisitFrequency: PediatricianVisitFrequency = .everyFewMonths,
		feedingFrequency: FeedingFrequency = .onDemand,
		childcareChallenges: [String] = [],
		bathingFrequency: BathingFrequency = .everyFewDays,
		aiUsageHistory: AIUsageHistory = .never
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
		self.isFirstChild = isFirstChild
		self.familySupport = familySupport
		self.overwhelmLevel = overwhelmLevel
		self.emotionalWellbeing = emotionalWellbeing
		self.householdType = householdType
		self.desiredFeatures = desiredFeatures
		self.internetUsageFrequency = internetUsageFrequency
		self.appDiscoverySource = appDiscoverySource
		self.teethingStatus = teethingStatus
		self.solidFoodStatus = solidFoodStatus
		self.pediatricianVisitFrequency = pediatricianVisitFrequency
		self.feedingFrequency = feedingFrequency
		self.childcareChallenges = childcareChallenges
		self.bathingFrequency = bathingFrequency
		self.aiUsageHistory = aiUsageHistory
    }
}
