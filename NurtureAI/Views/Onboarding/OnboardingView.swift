import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Environment(DependencyContainer.self) private var container
    @State private var viewModel: OnboardingViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                OnboardingContentView(viewModel: vm, showOnboarding: $showOnboarding)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            viewModel = OnboardingViewModel(babyRepository: container.babyRepository)
        }
    }
}

private struct OnboardingContentView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var showOnboarding: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView()
                case .babyName:
                    BabyNameStepView(viewModel: viewModel)
                case .babyDetails:
                    BabyDetailsStepView(viewModel: viewModel)
                case .done:
                    Color.clear.onAppear { showOnboarding = false }
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption)
                }

                if viewModel.currentStep != .done {
                    Button(viewModel.currentStep == .babyDetails ? "Get Started" : "Continue") {
                        if viewModel.currentStep == .babyDetails {
                            Task { await viewModel.saveBaby() }
                        } else {
                            viewModel.advance()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAdvance || viewModel.isLoading)
                    .overlay {
                        if viewModel.isLoading { ProgressView() }
                    }
                }
            }
            .padding(24)
            .navigationTitle("Welcome to NurtureAI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 72))
                .foregroundStyle(.pink)
            Text("Track sleep, feeding, and more — with AI-powered insights.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

private struct BabyNameStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's your baby's name?").font(.headline)
            TextField("Baby's name", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)
                .submitLabel(.continue)
        }
    }
}

private struct BabyDetailsStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section("Birthday") {
                DatePicker("Date of birth", selection: $viewModel.birthDate,
                           in: ...Date(), displayedComponents: .date)
            }
            Section("Gender (optional)") {
                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(Baby.Gender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
            }
            Section("Measurements (optional)") {
                TextField("Weight (kg)", text: $viewModel.weightKg)
                    .keyboardType(.decimalPad)
                TextField("Height (cm)", text: $viewModel.heightCm)
                    .keyboardType(.decimalPad)
            }
        }
    }
}
