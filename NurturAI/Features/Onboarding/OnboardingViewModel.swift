import Foundation
import SwiftData

@MainActor
@Observable
final class OnboardingViewModel {
    var draft = OnboardingDraft()
    var currentStep: OnboardingStep = .welcome
    var isSaving: Bool = false
    var error: String?

    /// Cached AI preview result. Stored on the ViewModel (not the step view's
    /// @State) so it survives the view recreation that happens when the user
    /// navigates back and forward through onboarding — once generated, the
    /// preview screen shows the same response on revisit instead of refetching.
    var cachedPreview: OnboardingPreview?

    enum OnboardingStep: Int, CaseIterable {
		case welcome
        case name
		case birthday
		case kidCount
		case familySupport
		case overwhelmed
		case wellBeing
		case household
		case challenges
		case feedingMethod
		case feedingFrequency
		case solidFoods
		case teething
		case bathing
		case pediatrician
		case birthWeight
		case currentWeight
		case features
		case internetUsage
		case aiUsage
		case appDiscovery
		case aiPreview
		case upsale

        var progress: Double {
			Double(rawValue + 1) / Double(OnboardingStep.allCases.count)        }
    }

    struct OnboardingDraft {
        var name: String = ""
        var birthDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        var feedingMethod: FeedingMethod = .breast
		var kidCount: FirstChild = .onlyChild

		// Extended onboarding answers
		var birthWeightGrams: Int = 0
		var currentWeightGrams: Int = 0
		var familySupport: FamilySupport = .preferNotToSay
		var overwhelmLevel: OverwhelmLevel = .preferNotToSay
		var emotionalWellbeing: EmotionalWellbeing = .preferNotToSay
		var householdType: HouseholdType = .preferNotToSay
		var desiredFeatures: Set<DesiredFeature> = []
		var internetUsageFrequency: InternetUsageFrequency = .sometimes
		var appDiscoverySource: AppDiscoverySource = .other
		var teethingStatus: TeethingStatus = .unsure
		var solidFoodStatus: SolidFoodStatus = .notYet
		var pediatricianVisitFrequency: PediatricianVisitFrequency = .everyFewMonths
		var feedingFrequency: FeedingFrequency = .onDemand
		var childcareChallenges: Set<ChildcareChallenge> = []
		var bathingFrequency: BathingFrequency = .everyFewDays
		var aiUsageHistory: AIUsageHistory = .never
    }

    var canAdvance: Bool {
        switch currentStep {
        case .name:           return !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthday:       return draft.birthDate <= .now
		default: return true
        }
    }

    func advance() {
        let steps = OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep),
              idx + 1 < steps.count
        else { return }
        currentStep = steps[idx + 1]
    }

    func back() {
        let steps = OnboardingStep.allCases
        guard let idx = steps.firstIndex(of: currentStep), idx > 0 else { return }
        currentStep = steps[idx - 1]
    }

    func complete(context: ModelContext, appState: AppState, syncService: FirestoreSyncService) async {
        isSaving = true
        error = nil

        guard let uid = appState.firebaseUID, !uid.isEmpty else {
            error = Strings.Errors.Onboarding.saveFailed
            isSaving = false
            return
        }

        let baby = Baby(
            name: draft.name.trimmingCharacters(in: .whitespaces),
            birthDate: draft.birthDate,
			feedingMethod: draft.feedingMethod,
			birthWeightGrams: draft.birthWeightGrams,
			currentWeightGrams: draft.currentWeightGrams,
			caregiverFirebaseUIDs: [uid],
			isFirstChild: draft.kidCount == .onlyChild,
			familySupport: draft.familySupport,
			overwhelmLevel: draft.overwhelmLevel,
			emotionalWellbeing: draft.emotionalWellbeing,
			householdType: draft.householdType,
			desiredFeatures: draft.desiredFeatures.map { $0.rawValue },
			internetUsageFrequency: draft.internetUsageFrequency,
			appDiscoverySource: draft.appDiscoverySource,
			teethingStatus: draft.teethingStatus,
			solidFoodStatus: draft.solidFoodStatus,
			pediatricianVisitFrequency: draft.pediatricianVisitFrequency,
			feedingFrequency: draft.feedingFrequency,
			childcareChallenges: draft.childcareChallenges.map { $0.rawValue },
			bathingFrequency: draft.bathingFrequency,
			aiUsageHistory: draft.aiUsageHistory
        )
        context.insert(baby)
        do {
            try context.save()
            try await syncService.syncBaby(baby)
            appState.currentBaby = baby
            appState.hasCompletedOnboarding = true
        } catch {
            self.error = Strings.Errors.Onboarding.saveFailed
        }
        isSaving = false
    }
}
