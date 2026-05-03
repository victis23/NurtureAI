//
//  FirstChild.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/2/26.
//

import SwiftUI

struct KidCountStepView: View {
	@Binding var firstChild: FirstChild
	
	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			VStack(alignment: .leading, spacing: 8) {
				Text(Strings.Onboarding.KidCount.heading)
					.font(NurturTypography.title2)
					.foregroundStyle(NurturColors.textPrimary)
				Text(Strings.Onboarding.KidCount.subheading)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}
			
			VStack(spacing: 12) {
				ForEach(FirstChild.allCases, id: \.self) { hasSiblings in
					Button {
						firstChild = hasSiblings
					} label: {
						HStack {
							Text(hasSiblings.displayName)
								.font(NurturTypography.headline)
							Spacer()
							if firstChild == hasSiblings {
								Image(systemName: "checkmark.circle.fill")
									.foregroundStyle(NurturColors.accent)
							}
						}
						.padding(18)
						.background(
							firstChild == hasSiblings ? NurturColors.accentSoft : NurturColors.surfaceWarm,
							in: RoundedRectangle(cornerRadius: 14)
						)
						.overlay(
							RoundedRectangle(cornerRadius: 14)
								.stroke(firstChild == hasSiblings ? NurturColors.accent : Color.clear, lineWidth: 2)
						)
						.foregroundStyle(NurturColors.textPrimary)
					}
				}
			}
		}
	}
}
