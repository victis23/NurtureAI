import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appContainer) private var container
    @State private var viewModel = OnboardingViewModel()
	@State private var contentOpacity: Double = 1
	private let fadeDuration: Double = 0.2
	private var showProgressBar: Bool = false
	@State private var buttonTap: Bool = false
	/// Guards against rapid Continue taps that could otherwise queue a second
	/// transition during the fade window — letting `advance()` fire twice and
	/// skip a step's gate (e.g. the birth weight check).
	@State private var isTransitioning: Bool = false
	/// True while the StoreKit purchase sheet is in flight from the upsale
	/// CTA. Locks both onboarding buttons so a second tap can't queue a
	/// duplicate purchase or finish-flow before StoreKit returns.
	@State private var isStartingTrial: Bool = false
	/// Surfaced under the upsale CTA when the trial purchase fails. Cleared
	/// on the next attempt.
	@State private var trialError: String?

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
                            .opacity(contentOpacity)
                            .id(viewModel.currentStep)

                        if let error = viewModel.error {
                            Text(error)
                                .font(NurturTypography.caption)
                                .foregroundStyle(NurturColors.danger)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(24)
                }
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 12) {
					Button(getButtonText(viewModel.currentStep)) {
						buttonTap.toggle()
						if viewModel.currentStep == .upsale {
							setupTrial()
						} else {
							advanceToNextView()
						}
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!viewModel.canAdvance || viewModel.isSaving || isTransitioning || isStartingTrial)
                    .overlay {
                        if viewModel.isSaving || isStartingTrial { ProgressView() }
                    }
					.sensoryFeedback(.impact, trigger: buttonTap)

					if viewModel.currentStep == .upsale, let trialError {
						Text(trialError)
							.font(NurturTypography.caption)
							.foregroundStyle(NurturColors.danger)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 8)
					}

					Button(viewModel.currentStep == .upsale ? Strings.Onboarding.tryForFree : Strings.Common.back) {
						transitionStep {
							buttonTap.toggle()
							if viewModel.currentStep == .upsale {
								advanceToNextView()
							} else {
								viewModel.back()
							}
						}
					}
					.font(NurturTypography.subheadline)
					.foregroundStyle(viewModel.currentStep != .welcome ? NurturColors.textSecondary : .clear)
					.disabled(viewModel.currentStep == .welcome || isStartingTrial)
					.sensoryFeedback(.impact, trigger: buttonTap)
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
		case .kidCount:
			KidCountStepView(firstChild: $viewModel.draft.kidCount)
		case .familySupport:
			FamilySupportStepView(familySupport: $viewModel.draft.familySupport)
		case .overwhelmed:
			OverWhelmLevelStepView(stepState: $viewModel.draft.overwhelmLevel)
		case .wellBeing:
			EmotionalWellbeingStepView(stepState: $viewModel.draft.emotionalWellbeing)
		case .household:
			HouseHoldTypeStepView(stepState: $viewModel.draft.householdType)
		case .challenges:
			ChildcareChallengeStepView(selection: $viewModel.draft.childcareChallenges)
        case .feedingMethod:
            FeedingMethodStepView(feedingMethod: $viewModel.draft.feedingMethod)
		case .feedingFrequency:
			FeedingFrequencyStepView(stepState: $viewModel.draft.feedingFrequency)
		case .solidFoods:
			SolidFoodStatusStepView(stepState: $viewModel.draft.solidFoodStatus)
		case .teething:
			TeethingStatusStepView(stepState: $viewModel.draft.teethingStatus)
		case .bathing:
			BathingFrequencyStepView(stepState: $viewModel.draft.bathingFrequency)
		case .pediatrician:
			PediatricianVisitStepView(stepState: $viewModel.draft.pediatricianVisitFrequency)
		case .birthWeight:
			BirthWeightStepView(grams: $viewModel.draft.birthWeightGrams)
		case .currentWeight:
			CurrentWeightStepView(grams: $viewModel.draft.currentWeightGrams)
		case .features:
			DesiredFeaturesStepView(selection: $viewModel.draft.desiredFeatures)
		case .internetUsage:
			InternetUsageStepView(stepState: $viewModel.draft.internetUsageFrequency)
		case .aiUsage:
			AIUsageHistoryStepView(stepState: $viewModel.draft.aiUsageHistory)
		case .appDiscovery:
			AppDiscoveryStepView(stepState: $viewModel.draft.appDiscoverySource)
		case .aiPreview:
			OnboardingPreviewStepView(draft: viewModel.draft, cached: $viewModel.cachedPreview)
		case .rating:
			RatingPromptStepView(onSkip: {
				transitionStep { viewModel.advance() }
			})
		case .upsale:
			PaywallView(isOnboarding: true)
        }
    }

	fileprivate func getButtonText(_ step: OnboardingViewModel.OnboardingStep) -> String {
		switch step {
		case .upsale:
			return Strings.Onboarding.useFreeTrial
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
			transitionStep { viewModel.advance() }
		}
	}

	/// Initiates the StoreKit purchase flow against Pro Monthly — the
	/// product configured with the 3-day Introductory Offer in App Store
	/// Connect. On success, `appState.isSubscribed` flips and the existing
	/// `.onChange` listener routes to `advanceToNextView()` which finishes
	/// onboarding. On user-cancel StoreKit returns without throwing and we
	/// stay on the upsale step. On a real error we surface it inline so
	/// the parent can retry or take the free plan via "Try Free Version".
	fileprivate func setupTrial() {
		guard let service = container?.subscriptionService else { return }
		isStartingTrial = true
		trialError = nil
		Task {
			do {
				try await service.purchase(product: .proMonthly)
			} catch {
				trialError = error.localizedDescription
			}
			isStartingTrial = false
		}
	}

	private func transitionStep(_ change: @escaping () -> Void) {
		guard !isTransitioning else { return }
		isTransitioning = true
		Task { @MainActor in
			withAnimation(.easeOut(duration: fadeDuration)) {
				contentOpacity = 0
			}
			try? await Task.sleep(for: .seconds(fadeDuration))
			change()
			withAnimation(.easeIn(duration: fadeDuration)) {
				contentOpacity = 1
			}
			isTransitioning = false
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
