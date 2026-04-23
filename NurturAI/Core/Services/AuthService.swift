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
    func signOut() throws
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

    func signOut() throws {
        try Auth.auth().signOut()
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

    var errorDescription: String? {
        "Sign in failed. Please try again."
    }
}
