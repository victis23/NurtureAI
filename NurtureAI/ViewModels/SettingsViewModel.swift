import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var apiKeyInput: String = ""
    var isAPIKeySet: Bool = false
    var isSavingKey = false
    var saveKeySuccess = false
    var errorMessage: String?

    private let keychain: KeychainHelper

    init(keychain: KeychainHelper = .shared) {
        self.keychain = keychain
        isAPIKeySet = (keychain.read(service: "NurtureAI", account: "openai-api-key") ?? "").isEmpty == false
    }

    // DEV ONLY: Remove this save function before TestFlight
    func saveAPIKey() {
        guard !apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "API key cannot be empty."
            return
        }
        isSavingKey = true
        let success = keychain.save(
            apiKeyInput.trimmingCharacters(in: .whitespaces),
            service: "NurtureAI",
            account: "openai-api-key"
        )
        if success {
            isAPIKeySet = true
            saveKeySuccess = true
            apiKeyInput = ""
        } else {
            errorMessage = "Failed to save API key to Keychain."
        }
        isSavingKey = false
    }

    func clearAPIKey() {
        _ = keychain.delete(service: "NurtureAI", account: "openai-api-key")
        isAPIKeySet = false
        apiKeyInput = ""
    }
}
