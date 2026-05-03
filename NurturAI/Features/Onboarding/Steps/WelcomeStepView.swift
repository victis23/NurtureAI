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
						.onboardingText()
				}
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
