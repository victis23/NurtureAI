import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container

    @State private var isLoading = false
    @State private var errorMessage: String?
	@Binding var showTermsAndConditions: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
				Image("nurturAi_icon")
					.resizable()
					.frame(width: 100, height: 100)
					.cornerRadius(25)

                VStack(spacing: 8) {
                    Text(Strings.Common.appName)
                        .font(NurturTypography.largeTitle)
                        .foregroundStyle(NurturColors.textPrimary)

                    Text(Strings.Auth.tagline)
                        .font(NurturTypography.subheadline)
                        .foregroundStyle(NurturColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

			VStack(spacing: 16) {
				if let errorMessage {
					Text(errorMessage)
						.font(NurturTypography.caption)
						.foregroundStyle(NurturColors.danger)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 32)
				}
				
				if isLoading {
					ProgressView()
						.frame(height: 50)
				} else {
					SignInWithAppleButton(.signIn) { request in
						guard let authService = container?.authService else { return }
						request.requestedScopes = [.fullName, .email]
						request.nonce = authService.prepareSignIn()
					} onCompletion: { result in
						Task { await handleResult(result) }
					}
					.signInWithAppleButtonStyle(.black)
					.frame(height: 50)
					.padding(.horizontal, 32)
				}
				
				Button {
					showTermsAndConditions = true
				} label: {
					Text(Strings.Auth.legalDisclaimer)
						.font(NurturTypography.caption2)
						.foregroundStyle(NurturColors.textFaint)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 32)
					
				}
			}
            .padding(.bottom, 52)
        }
        .background(NurturColors.background)
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) async {
        guard let authService = container?.authService else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.handleAppleCredential(result)
            appState.isAuthenticated = true
            appState.firebaseUID = authService.currentUID
        } catch {
            if (error as? ASAuthorizationError)?.code == .canceled {
                // User dismissed — not an error worth showing
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
