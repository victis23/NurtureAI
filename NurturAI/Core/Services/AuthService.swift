import Foundation

@MainActor
protocol AuthServiceProtocol {
    var isSignedIn: Bool { get }
    var currentUID: String? { get }
    func signInWithApple() async throws
    func signOut() throws
}

// Firebase Auth integration — stub in V1
@MainActor
final class AuthService: AuthServiceProtocol {
    var isSignedIn: Bool { false }
    var currentUID: String? { nil }

    func signInWithApple() async throws {
        // Phase 2: Sign in with Apple + Firebase Auth
    }

    func signOut() throws {
        // Phase 2: Firebase sign out
    }
}
