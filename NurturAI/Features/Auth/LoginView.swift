import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container

    @State private var isLoading = false
    @State private var errorMessage: String?
	@Binding var showTermsAndConditions: Bool
	@State private var loginHasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            loginBranding
				.opacity(loginHasAppeared ? 1 : 0)
				.offset(y: loginHasAppeared ? 0 : 16)

            Spacer()

			loginAuthCard
				.opacity(loginHasAppeared ? 1 : 0)
				.offset(y: loginHasAppeared ? 0 : 24)
				.padding(.horizontal, 20)
				.padding(.bottom, 36)
        }
        .nurturScreenBackground()
		.onAppear {
			container?.analyticsService.logPageView("loginView")
			withAnimation(NurturMotion.gentle) {
				loginHasAppeared = true
			}
		}
    }

	// MARK: - Branding

	private var loginBranding: some View {
		VStack(spacing: 20) {
			Image("nurturAi_icon")
				.resizable()
				.frame(width: 100, height: 100)
				.cornerRadius(25)
				.overlay(
					RoundedRectangle(cornerRadius: 25, style: .continuous)
						.strokeBorder(NurturGradients.glassRim, lineWidth: 1)
				)
				.shadow(color: NurturColors.accent.opacity(0.28), radius: 20, x: 0, y: 10)

			VStack(spacing: 8) {
				Text(Strings.Common.appName)
					.font(NurturTypography.largeTitle)
					.foregroundStyle(NurturColors.textPrimary)

				Text(Strings.Auth.tagline)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 32)
			}
		}
	}

	// MARK: - Auth card

	private var loginAuthCard: some View {
		VStack(spacing: 16) {
			if let errorMessage {
				Text(errorMessage)
					.font(NurturTypography.caption)
					.foregroundStyle(NurturColors.danger)
					.multilineTextAlignment(.center)
					.frame(maxWidth: .infinity)
					.padding(.horizontal, 12)
					.padding(.vertical, 10)
					.background(
						NurturColors.danger.opacity(0.08),
						in: RoundedRectangle(cornerRadius: 14, style: .continuous)
					)
					.overlay(
						RoundedRectangle(cornerRadius: 14, style: .continuous)
							.strokeBorder(NurturColors.danger.opacity(0.25), lineWidth: 1)
					)
			}

			if isLoading {
				ProgressView()
					.frame(height: 50)
			} else {
				// System Sign in with Apple button stays untouched for branding
				// compliance — only its glass container is styled.
				SignInWithAppleButton(.signIn) { request in
					guard let authService = container?.authService else { return }
					request.requestedScopes = [.fullName, .email]
					request.nonce = authService.prepareSignIn()
				} onCompletion: { result in
					Task { await handleResult(result) }
				}
				.signInWithAppleButtonStyle(.black)
				.frame(height: 50)
			}

			Button {
				showTermsAndConditions = true
			} label: {
				Text(Strings.Auth.legalDisclaimer)
					.font(NurturTypography.caption2)
					.foregroundStyle(NurturColors.textFaint)
					.multilineTextAlignment(.center)
			}
		}
		.padding(20)
		.frame(maxWidth: .infinity)
	}

    private func handleResult(_ result: Result<ASAuthorization, Error>) async {
		guard let authService = container?.authService, let syncService = container?.syncService else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.handleAppleCredential(result)

			if let skipOnboarding = await skipOnBoarding(syncService: syncService, uID: authService.currentUID) {
				appState.hasCompletedOnboarding = skipOnboarding
				container?.analyticsService.logEvent("recoveredAccount")
				// New sign-up (authenticated, no prior account data to restore) →
				// Meta CompleteRegistration funnel event. Returning users
				// (skipOnboarding == true) don't fire it.
				if !skipOnboarding {
					container?.analyticsService.logFunnelEvent(.completedRegistration)
				}
			}
			
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

	private func skipOnBoarding(syncService: FirestoreSyncService, uID: String?) async -> Bool? {
		guard let uID else { return false }
		var oldAccountData: FirestoreSyncService.BabyRestoreData?
		
		do {
			oldAccountData = try await syncService.fetchBabyForRestore(uid: uID)
		} catch {
			errorMessage = error.localizedDescription
			return nil
		}

		return oldAccountData != nil
	}
}

#Preview("Login") {
	@Previewable @State var showTerms = false
	LoginView(showTermsAndConditions: $showTerms)
		.environment(AppState.shared)
}
