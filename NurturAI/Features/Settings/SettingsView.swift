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
                        Text("Free Plan")
                            .font(NurturTypography.subheadline)
                            .fontWeight(.medium)
                        Text("3 AI queries per day")
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                    Spacer()
                    Button("Upgrade to Pro") { showPaywall = true }
                        .font(NurturTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NurturColors.accent, in: Capsule())
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

            #if DEBUG
            APIKeySection()
            #endif
        }
        .listStyle(.insetGrouped)
        .background(NurturColors.background)
        .errorAlert(error: $viewModel.error)
    }
}

#if DEBUG
private struct APIKeySection: View {
    @State private var apiKey: String = KeychainHelper.read(key: "openai_api_key") ?? ""
    @State private var saved: Bool = false

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(NurturColors.warning)
                    Text("OpenAI API Key")
                        .font(NurturTypography.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.success)
                    }
                }

                SecureField("sk-...", text: $apiKey)
                    .font(.system(.caption, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: apiKey) { saved = false }

                Button("Save to Keychain") {
                    KeychainHelper.write(key: "openai_api_key", value: apiKey.trimmingCharacters(in: .whitespaces))
                    saved = true
                }
                .font(NurturTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(NurturColors.accent)
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Developer")
        } footer: {
            Text("Debug builds only. Key is stored in Keychain and never logged.")
                .font(NurturTypography.caption2)
        }
    }
}
#endif
