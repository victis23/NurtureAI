import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    @State private var viewModel: SettingsViewModel?
    @State private var showPaywall: Bool = false
	@State private var showPendingFeature: Bool = false

    var body: some View {
            Group {
                if let vm = viewModel {
					ZStack {
						SettingsContentView(viewModel: vm, showPaywall: $showPaywall, showIsPendingFeature: $showPendingFeature)
						
						if showPendingFeature {
							PendingFeatureView()
								.transition(.scale.combined(with: .opacity))
						}
					}
					.animation(.easeInOut, value: showPendingFeature)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.Settings.navigationTitle)
			.task {
				guard let container else { return }
				let vm = SettingsViewModel(babyRepository: container.babyRepository, authService: container.authService, appState: appState)
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
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            // Baby profile
            Section(Strings.Settings.BabyProfile.sectionTitle) {
                if viewModel.isEditing {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name", text: $viewModel.editingName)
                            .textFieldStyle(.roundedBorder)
                        DatePicker("Birthday", selection: $viewModel.editingBirthDate, in: ...Date(), displayedComponents: .date)
                        HStack {
                            Button(Strings.Common.cancel) {
                                viewModel.isEditing = false
                            }
                            .foregroundStyle(NurturColors.textSecondary)
                            Spacer()
                            Button(Strings.Common.save) {
                                viewModel.saveEdits()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(NurturColors.accent)
                        }
                    }
                    .padding(.vertical, 4)
                } else if let baby = viewModel.baby {
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
                        Button(Strings.Common.edit) { viewModel.isEditing = true }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.accent)
                    }
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
					Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
						showIsPendingFeature = false
					})
                } label: {
                    Label(Strings.Settings.Caregivers.addCaregiver, systemImage: "person.badge.plus")
                        .foregroundStyle(NurturColors.textPrimary)
                }
            }

            // Links
            Section(Strings.Settings.Legal.sectionTitle) {
                Link(Strings.Settings.Legal.privacyPolicy, destination: URL(string: "https://nurtur.ai/privacy")!)
                    .foregroundStyle(NurturColors.textPrimary)
                Link(Strings.Settings.Legal.termsOfService, destination: URL(string: "https://nurtur.ai/terms")!)
                    .foregroundStyle(NurturColors.textPrimary)
            }

            // Sign out
            Section(Strings.Settings.Account.sectionTitle) {
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label(Strings.Settings.Account.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                }

				Button(role: .destructive) {
					
				} label: {
					Label(Strings.Settings.Account.deleteAccount, systemImage: "rectangle.portrait.and.arrow.right")
				}
            }

        }
        .listStyle(.insetGrouped)
        .background(NurturColors.background)
        .errorAlert(error: $viewModel.error)
    }
}

private struct PendingFeatureView: View {
	var body: some View {
		VStack(spacing: 15) {
			Image(systemName: "star")
			Text("Coming Soon!")
		}
		.frame(width: 300, height: 300, alignment: .center)
		.background(.white)
		.opacity(0.6)
		.shadow(radius: 0.2)
	}
}
