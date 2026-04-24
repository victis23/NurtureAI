import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    private let babyRepository: BabyRepositoryProtocol
    private let authService: AuthServiceProtocol
    private let appState: AppState

    var baby: Baby?
    var editingName: String = ""
    var editingBirthDate: Date = .now
    var isEditing: Bool = false
    var error: AppError?

    init(babyRepository: BabyRepositoryProtocol, authService: AuthServiceProtocol, appState: AppState) {
        self.babyRepository = babyRepository
        self.authService = authService
        self.appState = appState
    }

    func load() {
        do {
            baby = try babyRepository.fetchAll().first
            if let baby {
                editingName = baby.name
                editingBirthDate = baby.birthDate
            }
        } catch {
            self.error = .data(error)
        }
    }

    func saveEdits() {
        guard let baby else { return }
        baby.name = editingName.trimmingCharacters(in: .whitespaces)
        baby.birthDate = editingBirthDate
        do {
            try babyRepository.save(baby)
            isEditing = false
        } catch {
            self.error = .data(error)
        }
    }

    func signOut() {
        try? authService.signOut()
        appState.hasCompletedOnboarding = false
        appState.isAuthenticated = false
        appState.firebaseUID = nil
        appState.currentBaby = nil
    }

	//FIXME: Still need to also delete the repositories and remove firestore entries 
	func deleteAccount() {
		authService.deleteAccount()
		appState.hasCompletedOnboarding = false
		appState.isAuthenticated = false
		appState.firebaseUID = nil
		appState.currentBaby = nil
	}
}
