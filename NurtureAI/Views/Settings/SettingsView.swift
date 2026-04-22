import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Baby Profile") {
                if let baby = babies.first {
                    LabeledContent("Name", value: baby.name)
                    LabeledContent("Age", value: baby.ageDescription)
                    LabeledContent("Birthday", value: baby.birthDate.formatted(date: .long, time: .omitted))
                }
            }

            // DEV ONLY — Remove before TestFlight
            Section {
                if viewModel.isAPIKeySet {
                    HStack {
                        Label("API Key configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Button("Clear", role: .destructive) {
                            viewModel.clearAPIKey()
                        }
                        .font(.caption)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("OpenAI API Key (sk-...)", text: $viewModel.apiKeyInput)
                            .textContentType(.password)
                        Button("Save Key") {
                            viewModel.saveAPIKey()
                        }
                        .disabled(viewModel.apiKeyInput.isEmpty || viewModel.isSavingKey)
                    }
                }

                if viewModel.saveKeySuccess {
                    Label("Saved to Keychain", systemImage: "lock.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            } header: {
                Text("OpenAI API Key (DEV — Remove Before TestFlight)")
                    .foregroundStyle(.orange)
            } footer: {
                Text("Your key is stored in the iOS Keychain. Remove this section before submitting to TestFlight.")
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundStyle(.red).font(.caption) }
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
