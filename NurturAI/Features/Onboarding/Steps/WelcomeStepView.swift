//
//  WelcomeStepView.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/2/26.
//

import SwiftUI

struct WelcomeStepView: View {
	var body: some View {
		ScrollView {
			VStack {
				Text(Strings.Onboarding.Greeting.welcome)
					.font(NurturTypography.largeTitle)
					.foregroundStyle(.accentOrange)
					.padding(.top, 30)
				Text(Strings.Onboarding.Greeting.welcomeSubTitle)
					.font(NurturTypography.caption)
					.italic()

				Spacer()
					.frame(height: 50)
				
				VStack {
					Text(Strings.Onboarding.Greeting.greeting1)
						.multilineTextAlignment(.center)
						.font(NurturTypography.bodyMedium)
						.lineSpacing(10)
						.fontWeight(.light)
						.foregroundStyle(.black.opacity(0.7))
						.padding(10)
//					Text(Strings.Onboarding.Greeting.greeting3)
//						.multilineTextAlignment(.center)
//						.font(NurturTypography.title2)
//						.fontWeight(.light)
//						.padding(.horizontal, 20)
//						.padding(.top, 5)
				}
				.background(
					.ultraThinMaterial
						.opacity(0.5)
						.shadow(.drop(radius: 3)),
					in: RoundedRectangle(cornerRadius: 15)
				)
				.background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
			}
		}
		
	}
}

struct OnboardingView_preview: PreviewProvider {
	static var previews: some View {
		WelcomeStepView()
			.environment(AppState.shared)
	}
}
