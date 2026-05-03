//
//  HouseHoldTypeStep.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/3/26.
//

import SwiftUI

struct HouseHoldTypeStepView: View {
	@Binding var stepState: HouseholdType
	
	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			VStack(alignment: .leading, spacing: 8) {
				Text(Strings.Onboarding.Household.heading)
					.font(NurturTypography.title2)
					.foregroundStyle(NurturColors.textPrimary)
				Text(Strings.Onboarding.Household.subheading)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}
			
			VStack(spacing: 12) {
				ForEach(HouseholdType.allCases, id: \.self) { selectedAnswer in
					Button {
						stepState = selectedAnswer
					} label: {
						HStack {
							Text(selectedAnswer.displayName)
								.font(NurturTypography.headline)
							Spacer()
							if stepState == selectedAnswer {
								Image(systemName: "checkmark.circle.fill")
									.foregroundStyle(.white)
							}
						}
						.padding(18)
						.glassEffect(
							stepState == selectedAnswer
								? .regular.tint(NurturColors.accent).interactive()
								: .regular.interactive(),
							in: RoundedRectangle(cornerRadius: 14)
						)
						.foregroundStyle(stepState == selectedAnswer ? .white : NurturColors.textPrimary)
					}
				}
			}
			.sensoryFeedback(.selection, trigger: stepState)
		}
	}
}
