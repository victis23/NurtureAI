//
//  WelcomeStepView.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/2/26.
//

import SwiftUI

struct WelcomeStepView: View {
	var body: some View {
		VStack {
			Text(Strings.Onboarding.Greeting.welcome)
				.font(NurturTypography.largeTitle)
				.foregroundStyle(.accentOrange)
				.padding(.top, 20)
			Text(Strings.Onboarding.Greeting.welcomeSubTitle)
				.font(NurturTypography.caption)
				.italic()

			Spacer()

			Text(Strings.Onboarding.Greeting.greeting1)
				.multilineTextAlignment(.center)
				.font(NurturTypography.title3)
				.fontWeight(.heavy)
				.foregroundStyle(.accentOrange.opacity(0.7))
				.padding(5)

			VStack {
				Text(Strings.Onboarding.Greeting.greeting2)
					.multilineTextAlignment(.center)
					.font(NurturTypography.title2)
					.fontWeight(.light)
					.padding(20)
				Text(Strings.Onboarding.Greeting.greeting3)
					.multilineTextAlignment(.center)
					.font(NurturTypography.title2)
					.fontWeight(.light)
					.padding(20)
			}
			.background(
				.ultraThinMaterial
					.opacity(0.5)
					.shadow(.drop(radius: 3)),
				in: RoundedRectangle(cornerRadius: 15)
			)
			.background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
			
			Spacer()
		}
		
	}
}

struct OnboardingView_preview: PreviewProvider {
	static var previews: some View {
		WelcomeStepView()
			.environment(AppState.shared)
	}
}
