import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    @State private var viewModel: SettingsViewModel?
    @State private var showPaywall: Bool = false

    var body: some View {
            Group {
                if let vm = viewModel {
                    SettingsContentView(viewModel: vm, showPaywall: $showPaywall)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
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
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            // Baby profile
            Section("Baby Profile") {
                if viewModel.isEditing {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Name", text: $viewModel.editingName)
                            .textFieldStyle(.roundedBorder)
                        DatePicker("Birthday", selection: $viewModel.editingBirthDate, in: ...Date(), displayedComponents: .date)
                        HStack {
                            Button("Cancel") {
                                viewModel.isEditing = false
                            }
                            .foregroundStyle(NurturColors.textSecondary)
                            Spacer()
                            Button("Save") {
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
                        Button("Edit") { viewModel.isEditing = true }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.accent)
                    }
                }
            }

            // Subscription
            Section("Subscription") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.isSubscribed ? "Pro Plan" : "Free Plan")
                            .font(NurturTypography.subheadline)
                            .fontWeight(.medium)
                        Text(appState.isSubscribed ? "Unlimited AI queries" : "3 AI queries per day")
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                    Spacer()
                    if !appState.isSubscribed {
                        Button("Upgrade to Pro") { showPaywall = true }
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
            Section("Caregivers") {
                Button {
                    // Phase 2: Caregiver invite flow
                } label: {
                    Label("Add Caregiver", systemImage: "person.badge.plus")
                        .foregroundStyle(NurturColors.textPrimary)
                }
            }

            // Links
            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://nurtur.ai/privacy")!)
                    .foregroundStyle(NurturColors.textPrimary)
                Link("Terms of Service", destination: URL(string: "https://nurtur.ai/terms")!)
                    .foregroundStyle(NurturColors.textPrimary)
            }

            // Sign out
            Section {
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

        }
        .listStyle(.insetGrouped)
        .background(NurturColors.background)
        .errorAlert(error: $viewModel.error)
    }
}
