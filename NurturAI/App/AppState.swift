import Foundation
import FirebaseAuth

@MainActor
@Observable
final class AppState {
    var currentBaby: Baby?
    var isAuthenticated: Bool = false
    var firebaseUID: String?

    private var _hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var hasCompletedOnboarding: Bool {
        get { _hasCompletedOnboarding }
        set {
            _hasCompletedOnboarding = newValue
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
        }
    }

    var isSubscribed: Bool = false

    /// One-shot celebration trigger watched by the root-level confetti overlay.
    /// Setting it to a new UUID fires the Lottie; the overlay clears it back
    /// to nil after the animation. Set on first onboarding completion and on
    /// successful subscription purchase.
    var confettiTrigger: UUID? = nil

    static let shared = AppState()
    private init() {}

    func restoreAuthState() {
        if let user = Auth.auth().currentUser {
            isAuthenticated = true
            firebaseUID = user.uid
        }
    }
}
