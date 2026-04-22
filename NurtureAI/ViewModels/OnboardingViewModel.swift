import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    var name: String = ""
    var birthDate: Date = Date()
    var gender: Baby.Gender = .unknown
    var weightKg: String = ""
    var heightCm: String = ""
    var currentStep: Step = .welcome
    var isLoading = false
    var errorMessage: String?

    enum Step: Int, CaseIterable {
        case welcome
        case babyName
        case babyDetails
        case done
    }

    private let babyRepository: any BabyRepositoryProtocol

    init(babyRepository: any BabyRepositoryProtocol) {
        self.babyRepository = babyRepository
    }

    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .babyName: return name.count >= 1
        case .babyDetails: return true
        case .done: return false
        }
    }

    func advance() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func saveBaby() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your baby's name."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let baby = Baby(
                name: name.trimmingCharacters(in: .whitespaces),
                birthDate: birthDate,
                weightKg: Double(weightKg.replacingOccurrences(of: ",", with: ".")),
                heightCm: Double(heightCm.replacingOccurrences(of: ",", with: ".")),
                gender: gender
            )
            try await babyRepository.save(baby)
            currentStep = .done
        } catch {
            errorMessage = "Could not save baby profile. Please try again."
        }
        isLoading = false
    }
}
