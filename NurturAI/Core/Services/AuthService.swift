import Foundation
import AuthenticationServices
import FirebaseAuth
import CryptoKit

@MainActor
protocol AuthServiceProtocol {
    var isSignedIn: Bool { get }
    var currentUID: String? { get }
    func prepareSignIn() -> String
    func handleAppleCredential(_ result: Result<ASAuthorization, Error>) async throws
    /// Re-authenticate the currently signed-in user with a fresh Apple credential.
    /// Used before destructive operations (e.g. account deletion) so we never
    /// hit `requiresRecentLogin` mid-way through a multi-step delete.
    func handleAppleReauthCredential(_ result: Result<ASAuthorization, Error>) async throws
    func signOut() throws
    func deleteAccount() async throws
}

@MainActor
final class AuthService: AuthServiceProtocol {

    private var currentNonce: String?

    var isSignedIn: Bool { Auth.auth().currentUser != nil }
    var currentUID: String? { Auth.auth().currentUser?.uid }

    // Generates and stores the raw nonce, returns the hashed version for the Apple request
    func prepareSignIn() -> String {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        return Self.sha256(nonce)
    }

    func handleAppleCredential(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()

        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        try await Auth.auth().signIn(with: firebaseCredential)
        currentNonce = nil
    }

    func handleAppleReauthCredential(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()

        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let tokenData = appleCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }
        guard let user = Auth.auth().currentUser else {
            throw AuthError.notSignedIn
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        try await user.reauthenticate(with: firebaseCredential)
        currentNonce = nil
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        // Callers MUST re-authenticate via `handleAppleReauthCredential` first.
        // With a fresh token in hand, `requiresRecentLogin` cannot fire here.
        try await user.delete()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case notSignedIn
    /// Retained for binary/source compatibility — no longer thrown by `deleteAccount()`
    /// now that re-auth is performed up-front.
    case requiresRecentLogin

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return Strings.Errors.Auth.invalidCredential
        case .notSignedIn:
            return "You must be signed in to perform this action."
        case .requiresRecentLogin:
            return "For your security, please sign in again before deleting your account."
        }
    }
}
