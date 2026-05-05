import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    @State private var viewModel: SettingsViewModel?
    @State private var showPaywall: Bool = false
	@State private var showPendingFeature: Bool = false
	@State private var showDeleteConfirmation: Bool = false
	@State private var showReauthSheet: Bool = false
	@State private var showResetAIMemoryConfirmation: Bool = false

    var body: some View {
            Group {
                if let vm = viewModel {
					ZStack {
						SettingsContentView(
							viewModel: vm,
							showPaywall: $showPaywall,
							showIsPendingFeature: $showPendingFeature,
							showDeleteConfirmation: $showDeleteConfirmation,
							showResetAIMemoryConfirmation: $showResetAIMemoryConfirmation
						)

						PendingFeatureView()
							.opacity(showPendingFeature ? 1 : 0)
							.scaleEffect(showPendingFeature ? 1 : 0.8)
							.allowsHitTesting(showPendingFeature)
							.animation(.easeInOut(duration: 0.5), value: showPendingFeature)
					}
					.alert(Strings.Settings.Account.deleteAlertTitle, isPresented: $showDeleteConfirmation) {
						Button(Strings.Common.cancel, role: .cancel) { }
						Button(Strings.Settings.Account.deleteConfirm, role: .destructive) {
							// Don't touch any data yet — present the re-auth sheet first.
							showReauthSheet = true
						}
					} message: {
						Text(Strings.Settings.Account.deleteAlertBody)
					}
					.alert(Strings.Settings.AI.resetAlertTitle, isPresented: $showResetAIMemoryConfirmation) {
						Button(Strings.Common.cancel, role: .cancel) { }
						Button(Strings.Settings.AI.resetConfirm, role: .destructive) {
							vm.resetAIMemory()
						}
					} message: {
						Text(Strings.Settings.AI.resetAlertBody)
					}
					.sheet(isPresented: $showReauthSheet) {
						DeleteReauthSheet(viewModel: vm) {
							showReauthSheet = false
						}
					}
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.Settings.navigationTitle)
			.task {
				guard let container else { return }
				let vm = SettingsViewModel(
					babyRepository: container.babyRepository,
					authService: container.authService,
					syncService: container.syncService,
					notificationService: container.notificationService,
					appState: appState
				)
				viewModel = vm
				vm.load()
			}
			.sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

private struct SettingsContentView: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var showPaywall: Bool
	@Binding var showIsPendingFeature: Bool
	@Binding var showDeleteConfirmation: Bool
	@Binding var showResetAIMemoryConfirmation: Bool
    @Environment(AppState.self) private var appState

    /// Drives the field edit sheet. Set by tapping any editable row; the
    /// sheet binds to it via `.sheet(item:)`.
    @State private var fieldToEdit: EditableField? = nil

    var body: some View {
        List {
            // Baby identity hero row (read-only summary; details are edited via the rows below)
            if let baby = viewModel.baby {
                Section {
                    HStack {
                        BabyAvatar(name: baby.name, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(baby.name)
                                .font(NurturTypography.subheadline)
                                .fontWeight(.medium)
                            Text(baby.displayAge)
                                .font(NurturTypography.caption)
                                .foregroundStyle(NurturColors.textSecondary)
                        }
                        Spacer()
                    }
                }

                Section(Strings.Settings.Edit.yourBabySection) {
                    editableRow(.name, baby: baby)
                    editableRow(.birthday, baby: baby)
                    editableRow(.kidCount, baby: baby)
                    editableRow(.birthWeight, baby: baby)
                    editableRow(.currentWeight, baby: baby)
                    editableRow(.teething, baby: baby)
                    editableRow(.solidFoods, baby: baby)
                }

                Section(Strings.Settings.Edit.dailyCareSection) {
                    editableRow(.feedingMethod, baby: baby)
                    editableRow(.feedingFrequency, baby: baby)
                    editableRow(.bathing, baby: baby)
                    editableRow(.pediatrician, baby: baby)
                }

                Section(Strings.Settings.Edit.familySection) {
                    editableRow(.household, baby: baby)
                    editableRow(.familySupport, baby: baby)
                    editableRow(.challenges, baby: baby)
                }

                Section(Strings.Settings.Edit.wellbeingSection) {
                    editableRow(.wellbeing, baby: baby)
                    editableRow(.overwhelm, baby: baby)
                }

                Section(Strings.Settings.Edit.appSection) {
                    editableRow(.features, baby: baby)
                    editableRow(.internetUsage, baby: baby)
                    editableRow(.aiUsage, baby: baby)
                    editableRow(.appDiscovery, baby: baby)
                }
            }

            // Subscription
            Section(Strings.Settings.Subscription.sectionTitle) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.isSubscribed ? Strings.Settings.Subscription.proPlan : Strings.Settings.Subscription.freePlan)
                            .font(NurturTypography.subheadline)
                            .fontWeight(.medium)
                        Text(appState.isSubscribed ? Strings.Settings.Subscription.proDescription : Strings.Settings.Subscription.freeDescription)
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                    Spacer()
                    if !appState.isSubscribed {
                        Button(Strings.Settings.Subscription.upgradeToPro) { showPaywall = true }
                            .font(NurturTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NurturColors.accent, in: Capsule())
                    }
                }
            }

            // Caregivers
            Section(Strings.Settings.Caregivers.sectionTitle) {
                Button {
                    // Phase 2: Caregiver invite flow
					showIsPendingFeature = true
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(1))
						showIsPendingFeature = false
					}
                } label: {
                    Label(Strings.Settings.Caregivers.addCaregiver, systemImage: "person.badge.plus")
                        .foregroundStyle(NurturColors.textPrimary)
                }
            }

            // Links
            Section(Strings.Settings.Legal.sectionTitle) {
				NavigationLink(Strings.Settings.Legal.privacyPolicy) {
					PrivacyPolicy()
				}
				
				NavigationLink(Strings.Settings.Legal.termsOfService) {
					TermsAndConditions(
						showTermsAndConditions: Binding(get: {
							false
						}, set: { _ in
						}),
						hideDoneButton: true
					)
				}
            }

            // AI memory
            Section(Strings.Settings.AI.sectionTitle) {
                Button(role: .destructive) {
                    showResetAIMemoryConfirmation = true
                } label: {
                    Label(Strings.Settings.AI.resetMemory, systemImage: "brain")
                }
            }

            // Sign out
            Section(Strings.Settings.Account.sectionTitle) {
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label(Strings.Settings.Account.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                }

				Button(role: .destructive) {
					showDeleteConfirmation = true
				} label: {
					Label(Strings.Settings.Account.deleteAccount, systemImage: "trash")
				}
				.disabled(viewModel.isDeletingAccount)
            }

        }
        .listStyle(.insetGrouped)
        .background(NurturColors.background)
        .errorAlert(error: $viewModel.error)
        .sheet(item: $fieldToEdit) { field in
            if let baby = viewModel.baby {
                FieldEditSheet(field: field, baby: baby) {
                    viewModel.saveBaby()
                }
            }
        }
    }

    @ViewBuilder
    private func editableRow(_ field: EditableField, baby: Baby) -> some View {
        Button {
            fieldToEdit = field
        } label: {
            HStack {
                Text(field.label)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textPrimary)
                Spacer(minLength: 12)
                Text(field.currentValueText(for: baby))
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textFaint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PendingFeatureView: View {
	var body: some View {
		VStack(spacing: 15) {
			Image(systemName: "star.fill")
				.font(.system(size: 50))
				.foregroundStyle(Color.yellow)
				.symbolEffect(.pulse, options: .speed(3.0))
			Text(Strings.Settings.Caregivers.pendingFeatureTitle)
				.foregroundStyle(.accentOrange)
				.fontWeight(.heavy)
		}
		.frame(width: 150, height: 150, alignment: .center)
		.background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 15))
		.overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
			.strokeBorder(.accentOrange, lineWidth: 1)
			.shadow(radius: 15))
	}
}

/// Forces a fresh Sign in with Apple before any destructive delete work runs.
/// Nothing in `SettingsViewModel.deleteAccount()` executes unless re-auth succeeds —
/// so cancelling here leaves the user fully intact.
private struct DeleteReauthSheet: View {
	@Bindable var viewModel: SettingsViewModel
	let onDismiss: () -> Void

	@Environment(\.appContainer) private var container
	@State private var isWorking = false
	@State private var errorMessage: String?

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "lock.shield")
				.font(.system(size: 44))
				.foregroundStyle(NurturColors.accent)
				.padding(.top, 32)

			Text(Strings.Settings.Account.reauthTitle)
				.font(NurturTypography.title3)
				.fontWeight(.semibold)

			Text(Strings.Settings.Account.reauthMessage)
				.font(NurturTypography.subheadline)
				.foregroundStyle(NurturColors.textSecondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 24)

			if let errorMessage {
				Text(errorMessage)
					.font(NurturTypography.caption)
					.foregroundStyle(NurturColors.danger)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 24)
			}

			Spacer()

			if isWorking {
				ProgressView()
					.frame(height: 50)
			} else {
				SignInWithAppleButton(.continue) { request in
					guard let authService = container?.authService else { return }
					request.requestedScopes = [.fullName, .email]
					request.nonce = authService.prepareSignIn()
				} onCompletion: { result in
					Task { await handleReauth(result) }
				}
				.signInWithAppleButtonStyle(.black)
				.frame(height: 50)
				.padding(.horizontal, 32)
			}

			Button(Strings.Settings.Account.reauthCancel) {
				onDismiss()
			}
			.foregroundStyle(NurturColors.textSecondary)
			.padding(.bottom, 24)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(NurturColors.background)
		.interactiveDismissDisabled(isWorking)
	}

	private func handleReauth(_ result: Result<ASAuthorization, Error>) async {
		guard let authService = container?.authService else { return }
		isWorking = true
		errorMessage = nil
		do {
			try await authService.handleAppleReauthCredential(result)
			// Re-auth succeeded — proceed with the actual destructive work.
			await viewModel.deleteAccount()
			onDismiss()
		} catch {
			if (error as? ASAuthorizationError)?.code == .canceled {
				// User dismissed Apple sheet — leave the reauth sheet open so they can retry.
			} else {
				errorMessage = error.localizedDescription
			}
		}
		isWorking = false
	}
}
