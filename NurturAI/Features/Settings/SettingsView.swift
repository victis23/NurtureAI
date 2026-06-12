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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .nurturScreenBackground()
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
        ScrollView {
            GlassEffectContainer {
                VStack(spacing: 20) {
                    // Baby identity hero row (read-only summary; details are edited via the rows below)
                    if let baby = viewModel.baby {
                        heroCard(baby: baby)

                        SettingsSectionCard(Strings.Settings.Edit.yourBabySection) {
                            editableRow(.name, baby: baby)
                            editableRow(.birthday, baby: baby)
                            editableRow(.kidCount, baby: baby)
                            editableRow(.birthWeight, baby: baby)
                            editableRow(.currentWeight, baby: baby)
                            editableRow(.teething, baby: baby)
                            editableRow(.solidFoods, baby: baby, showsDivider: false)
                        }

                        SettingsSectionCard(Strings.Settings.Edit.dailyCareSection) {
                            editableRow(.feedingMethod, baby: baby)
                            editableRow(.feedingFrequency, baby: baby)
                            editableRow(.bathing, baby: baby)
                            editableRow(.pediatrician, baby: baby, showsDivider: false)
                        }

                        SettingsSectionCard(Strings.Settings.Edit.familySection) {
                            editableRow(.household, baby: baby)
                            editableRow(.familySupport, baby: baby)
                            editableRow(.challenges, baby: baby, showsDivider: false)
                        }

                        SettingsSectionCard(Strings.Settings.Edit.wellbeingSection) {
                            editableRow(.wellbeing, baby: baby)
                            editableRow(.overwhelm, baby: baby, showsDivider: false)
                        }

                        SettingsSectionCard(Strings.Settings.Edit.appSection) {
                            editableRow(.features, baby: baby)
                            editableRow(.internetUsage, baby: baby)
                            editableRow(.aiUsage, baby: baby)
                            editableRow(.appDiscovery, baby: baby, showsDivider: false)
                        }
                    }

                    // Subscription
                    SettingsSectionCard(Strings.Settings.Subscription.sectionTitle) {
                        HStack(spacing: 12) {
                            GlassIconBadge(
                                icon: appState.isSubscribed ? "crown.fill" : "sparkles",
                                color: NurturColors.warning,
                                size: 30
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isSubscribed ? Strings.Settings.Subscription.proPlan : Strings.Settings.Subscription.freePlan)
                                    .font(NurturTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(NurturColors.textPrimary)
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
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(NurturGradients.accent, in: Capsule())
                                    .shadow(color: NurturColors.accent.opacity(0.28), radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    // Caregivers
                    SettingsSectionCard(Strings.Settings.Caregivers.sectionTitle) {
                        Button {
                            // Phase 2: Caregiver invite flow
							showIsPendingFeature = true
							Task { @MainActor in
								try? await Task.sleep(for: .seconds(1))
								showIsPendingFeature = false
							}
                        } label: {
                            settingsRow(
                                icon: "person.badge.plus",
                                color: NurturColors.success,
                                title: Strings.Settings.Caregivers.addCaregiver,
                                showsDivider: false
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Links
                    SettingsSectionCard(Strings.Settings.Legal.sectionTitle) {
                        NavigationLink {
                            PrivacyPolicy()
                        } label: {
                            settingsRow(
                                icon: "hand.raised.fill",
                                color: NurturColors.info,
                                title: Strings.Settings.Legal.privacyPolicy
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TermsAndConditions(
                                showTermsAndConditions: Binding(get: {
                                    false
                                }, set: { _ in
                                }),
                                hideDoneButton: true
                            )
                        } label: {
                            settingsRow(
                                icon: "doc.text.fill",
                                color: NurturColors.info,
                                title: Strings.Settings.Legal.termsOfService,
                                showsDivider: false
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // AI memory
                    SettingsSectionCard(Strings.Settings.AI.sectionTitle) {
                        Button(role: .destructive) {
                            showResetAIMemoryConfirmation = true
                        } label: {
                            settingsRow(
                                icon: "brain",
                                color: NurturColors.danger,
                                title: Strings.Settings.AI.resetMemory,
                                titleColor: NurturColors.danger,
                                showsChevron: false,
                                showsDivider: false
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Sign out
                    SettingsSectionCard(Strings.Settings.Account.sectionTitle) {
                        Button(role: .destructive) {
                            viewModel.signOut()
                        } label: {
                            settingsRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                color: NurturColors.danger,
                                title: Strings.Settings.Account.signOut,
                                titleColor: NurturColors.danger,
                                showsChevron: false
                            )
                        }
                        .buttonStyle(.plain)

						Button(role: .destructive) {
							showDeleteConfirmation = true
						} label: {
                            settingsRow(
                                icon: "trash",
                                color: NurturColors.danger,
                                title: Strings.Settings.Account.deleteAccount,
                                titleColor: NurturColors.danger,
                                showsChevron: false,
                                showsDivider: false
                            )
						}
						.buttonStyle(.plain)
						.disabled(viewModel.isDeletingAccount)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .scrollContentBackground(.hidden)
        .nurturScreenBackground()
        .errorAlert(error: $viewModel.error)
        .sheet(item: $fieldToEdit) { field in
            if let baby = viewModel.baby {
                FieldEditSheet(field: field, baby: baby) {
                    viewModel.saveBaby()
                }
            }
        }
    }

    // MARK: - Hero identity card

    private func heroCard(baby: Baby) -> some View {
        HStack(spacing: 14) {
            BabyAvatar(name: baby.name, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(baby.name)
                    .font(NurturTypography.title3)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(baby.displayAge)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textSecondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nurturGlassCard(cornerRadius: 28)
    }

    // MARK: - Rows

    @ViewBuilder
    private func editableRow(_ field: EditableField, baby: Baby, showsDivider: Bool = true) -> some View {
        VStack(spacing: 0) {
            Button {
                fieldToEdit = field
            } label: {
                HStack(spacing: 12) {
                    GlassIconBadge(icon: field.settingsIcon, color: field.settingsIconColor, size: 30)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsDivider {
                SettingsGlassDivider()
            }
        }
    }

    /// Shared static row (caregivers, legal, account actions) matching the
    /// editable rows' badge + chevron rhythm.
    private func settingsRow(
        icon: String,
        color: Color,
        title: String,
        titleColor: Color = NurturColors.textPrimary,
        showsChevron: Bool = true,
        showsDivider: Bool = true
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                GlassIconBadge(icon: icon, color: color, size: 30)
                Text(title)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(titleColor)
                Spacer(minLength: 12)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(NurturColors.textFaint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())

            if showsDivider {
                SettingsGlassDivider()
            }
        }
    }
}

// MARK: - Glass section card

/// Eyebrow header + a single floating glass card wrapping that section's rows.
private struct SettingsSectionCard<Content: View>: View {
    let title: String?
    private let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                NurturSectionHeader(title: title)
            }
            VStack(spacing: 0) {
                content
            }
            .nurturGlassCard(cornerRadius: 24)
        }
    }
}

/// Hairline separator between rows inside a glass section card, inset past
/// the icon badge so titles stay optically aligned.
private struct SettingsGlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(NurturColors.textPrimary.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 58)
    }
}

// MARK: - Row icon mapping (visual only)

private extension EditableField {
    /// SF Symbol shown in the row's glass icon badge.
    var settingsIcon: String {
        switch self {
        case .name:             return "textformat"
        case .birthday:         return "birthday.cake.fill"
        case .kidCount:         return "figure.2.and.child.holdinghands"
        case .birthWeight:      return "scalemass"
        case .currentWeight:    return "scalemass.fill"
        case .teething:         return "mouth.fill"
        case .solidFoods:       return "fork.knife"
        case .feedingMethod:    return "drop.fill"
        case .feedingFrequency: return "clock.fill"
        case .bathing:          return "bathtub.fill"
        case .pediatrician:     return "stethoscope"
        case .household:        return "house.fill"
        case .familySupport:    return "person.2.fill"
        case .challenges:       return "exclamationmark.bubble.fill"
        case .wellbeing:        return "heart.fill"
        case .overwhelm:        return "wind"
        case .features:         return "sparkles"
        case .internetUsage:    return "globe"
        case .aiUsage:          return "brain.head.profile"
        case .appDiscovery:     return "megaphone.fill"
        }
    }

    /// Badge tint for the row icon.
    var settingsIconColor: Color {
        switch self {
        case .name, .birthday, .household, .features, .appDiscovery:
            return NurturColors.accent
        case .kidCount, .birthWeight, .currentWeight, .feedingMethod, .internetUsage, .aiUsage:
            return NurturColors.info
        case .teething, .feedingFrequency, .challenges, .overwhelm:
            return NurturColors.warning
        case .solidFoods, .bathing, .familySupport:
            return NurturColors.success
        case .pediatrician, .wellbeing:
            return NurturColors.danger
        }
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
		.nurturGlassCardTinted(NurturColors.accent, cornerRadius: 24)
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
			GlassIconBadge(icon: "lock.shield.fill", color: NurturColors.accent, size: 72)
				.padding(.top, 32)

			Text(Strings.Settings.Account.reauthTitle)
				.font(NurturTypography.title3)
				.fontWeight(.semibold)
				.foregroundStyle(NurturColors.textPrimary)

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
		.nurturScreenBackground(animated: false)
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
