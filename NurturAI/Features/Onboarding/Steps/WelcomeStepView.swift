//
//  WelcomeStepView.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/2/26.
//

import SwiftUI

struct WelcomeStepView: View {
	var body: some View {
		VStack(spacing: 10) {
			Text(Strings.Onboarding.Greeting.welcome)
				.font(NurturTypography.largeTitle)
				.foregroundStyle(NurturColors.accent)
				.multilineTextAlignment(.center)
				.shadow(color: NurturColors.accent.opacity(0.18), radius: 12, x: 0, y: 4)
			Text(Strings.Onboarding.Greeting.welcomeSubTitle)
				.font(NurturTypography.subheadline)
				.italic()
				.foregroundStyle(NurturColors.textSecondary)
				.multilineTextAlignment(.center)

			Spacer()
				.frame(height: 40)

			Text(Strings.Onboarding.Greeting.greeting1)
				.onboardingText()
		}
		.padding(.top, 30)
	}
}

struct OnboardingView_preview: PreviewProvider {
	static var previews: some View {
		WelcomeStepView()
			.environment(AppState.shared)
	}
}
