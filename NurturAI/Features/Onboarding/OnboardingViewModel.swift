import Foundation
import SwiftData

@MainActor
@Observable
final class OnboardingViewModel {
    var draft = OnboardingDraft()
    var currentStep: OnboardingStep = .name
    var isSaving: Bool = false
    var error: String?

    enum OnboardingStep: Int, CaseIterable {
        case name, birthday, feedingMethod

        var progress: Double {
			Double(rawValue + 1) / Double(OnboardingStep.allCases.count)        }
    }

    struct OnboardingDraft {
        var name: String = ""
        var birthDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        var feedingMethod: FeedingMethod = .breast
    }

    var canAdvance: Bool {
        switch currentStep {
        case .name:           return !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthday:       return draft.birthDate <= .now
        case .feedingMethod:  return true
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
            birthWeightGrams: 0,
            currentWeightGrams: 0,
            caregiverFirebaseUIDs: [uid]
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
