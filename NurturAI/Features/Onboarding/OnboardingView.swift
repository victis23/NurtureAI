import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appContainer) private var container
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressBar(progress: viewModel.currentStep.progress)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView {
                    VStack(spacing: 32) {
                        stepContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(viewModel.currentStep)

                        if let error = viewModel.error {
                            Text(error)
                                .font(NurturTypography.caption)
                                .foregroundStyle(NurturColors.danger)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
                }
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 12) {
                    Button(viewModel.currentStep == .feedingMethod ? Strings.Onboarding.getStarted : Strings.Onboarding.continueButton) {
                        if viewModel.currentStep == .feedingMethod {
                            guard let syncService = container?.syncService else { return }
                            Task { await viewModel.complete(context: modelContext, appState: appState, syncService: syncService) }
                        } else {
                            viewModel.advance()
                        }
                    }
                    .primaryButton()
                    .disabled(!viewModel.canAdvance || viewModel.isSaving)
                    .overlay {
                        if viewModel.isSaving { ProgressView() }
                    }

                    if viewModel.currentStep != .name {
                        Button(Strings.Common.back) { viewModel.back() }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
			.background(alignment: .center, content: {
					Image("onboarding_name")
						.resizable()
						.scaledToFill()
						.ignoresSafeArea()
						.opacity(0.5)
						.transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
			})
            .navigationTitle(Strings.Onboarding.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
	}

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .name:
            BabyNameStepView(name: $viewModel.draft.name)
        case .birthday:
            BabyBirthdayStepView(birthDate: $viewModel.draft.birthDate)
        case .feedingMethod:
            FeedingMethodStepView(feedingMethod: $viewModel.draft.feedingMethod)
        }
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(NurturColors.surfaceWarm).frame(height: 4)
                Capsule()
                    .fill(NurturColors.accent)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}
