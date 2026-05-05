import Foundation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    private let babyRepository: BabyRepositoryProtocol
    private let authService: AuthServiceProtocol
    private let syncService: FirestoreSyncService
    private let notificationService: NotificationService
    private let appState: AppState

    var baby: Baby?
    var error: AppError?
    var isDeletingAccount: Bool = false

    init(
        babyRepository: BabyRepositoryProtocol,
        authService: AuthServiceProtocol,
        syncService: FirestoreSyncService,
        notificationService: NotificationService,
        appState: AppState
    ) {
        self.babyRepository = babyRepository
        self.authService = authService
        self.syncService = syncService
        self.notificationService = notificationService
        self.appState = appState
    }

    func load() {
        do {
            baby = try babyRepository.fetchAll().first
        } catch {
            self.error = .data(error)
        }
    }

    /// Persists the in-memory mutations made by `FieldEditSheet`. The sheet
    /// writes new values onto the Baby (a SwiftData @Model reference type)
    /// when the user taps Save; this just commits them to disk.
    func saveBaby() {
        guard let baby else { return }
        do {
            try babyRepository.save(baby)
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

    /// Wipes the Assist conversation thread + the rolling `historical_context`
    /// summary the AI uses as long-term memory. The next visit to the Assist
    /// tab will rebuild a fresh `AssistViewModel` reading empty state.
    func resetAIMemory() {
        AssistViewModel.resetAIMemory()
    }

    /// Permanently deletes the user's account and all associated data.
    ///
    /// Order is critical:
    ///   1. Capture babyID  — needed before local data is wiped.
    ///   2. Firestore delete — must run while the Auth token is still valid.
    ///   3. Cancel notifications — no point in firing reminders for a deleted account.
    ///   4. Wipe local SwiftData — Baby cascade-deletes BabyLog + AIInsight.
    ///   5. Delete Firebase Auth user — irreversible.
    ///   6. Clear AppState — last, so any earlier failure leaves the user recoverable.
    func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        let babyID = baby?.id ?? (try? babyRepository.fetchAll().first?.id) ?? nil

        // 2. Firestore (skipped if no baby document exists yet)
        if let babyID {
            do {
                try await syncService.deleteBaby(babyID: babyID)
            } catch {
                self.error = .data(error)
                return
            }
        }

        // 3. Notifications
        notificationService.cancelAll()

        // 4. Local SwiftData
        do {
            try babyRepository.deleteAll()
        } catch {
            self.error = .data(error)
            return
        }

        // 5. Firebase Auth
        do {
            try await authService.deleteAccount()
        } catch {
            // Surface re-auth and other errors so the UI can react.
            self.error = .auth(error)
            return
        }

        // 6. AppState
        baby = nil
        appState.hasCompletedOnboarding = false
        appState.isAuthenticated = false
        appState.firebaseUID = nil
        appState.currentBaby = nil
    }
}
