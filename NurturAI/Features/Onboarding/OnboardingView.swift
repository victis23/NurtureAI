import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appContainer) private var container
    @State private var viewModel = OnboardingViewModel()
	var showProgressBar: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
				if showProgressBar {
					ProgressBar(progress: viewModel.currentStep.progress)
						.padding(.horizontal, 24)
						.padding(.top, 16)

				}

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
					Button(getButtonText(viewModel.currentStep)) {
						advanceToNextView()
                    }
                    .primaryButton()
                    .disabled(!viewModel.canAdvance || viewModel.isSaving)
                    .overlay {
                        if viewModel.isSaving { ProgressView() }
                    }

                    if viewModel.currentStep != .welcome {
                        Button(Strings.Common.back) { viewModel.back() }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
			.background(alignment: .center, content: {
				if viewModel.currentStep != .upsale {
					VStack {
						Spacer()
							.frame(height: 350)
						CharacterView(state: .relaxing)
							.opacity(0.8)
							.frame(width: 600, height: 600)
							.padding(.bottom, 150)
					}
				}
			})
			.navigationTitle(viewModel.currentStep != .welcome ? Strings.Onboarding.navigationTitle : "")
            .navigationBarTitleDisplayMode(.inline)
			.onChange(of: appState.isSubscribed) {
				NSLog("[Onboarding] - App Subscribe State Triggered")
				advanceToNextView()
			}
        }
	}

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
		case .welcome:
			WelcomeStepView()
        case .name:
            BabyNameStepView(name: $viewModel.draft.name)
        case .birthday:
            BabyBirthdayStepView(birthDate: $viewModel.draft.birthDate)
        case .feedingMethod:
            FeedingMethodStepView(feedingMethod: $viewModel.draft.feedingMethod)
		case .upsale:
			PaywallView(isOnboarding: true)
        }
    }

	fileprivate func getButtonText(_ step: OnboardingViewModel.OnboardingStep) -> String {
		switch step {
		case .upsale:
			return Strings.Onboarding.getStarted
		default:
			return Strings.Onboarding.continueButton
		}
	}

	fileprivate func advanceToNextView() {
		if viewModel.currentStep == .upsale {
			guard let syncService = container?.syncService else { return }
			Task {
				await viewModel.complete(
					context: modelContext,
					appState: appState,
					syncService: syncService
				)
			}
		} else {
			viewModel.advance()
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

struct View_preview: PreviewProvider {
	static var previews: some View {
		OnboardingView()
			.environment(AppState.shared)
	}
}
