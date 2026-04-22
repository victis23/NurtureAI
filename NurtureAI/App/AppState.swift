import Foundation

@MainActor
@Observable
final class AppState {
    var currentBaby: Baby?
    var isAuthenticated: Bool = false
    var firebaseUID: String?

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    var isSubscribed: Bool = false

    static let shared = AppState()
    private init() {}
}
