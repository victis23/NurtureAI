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
		VStack(alignment: .leading, spacing: 20) {
			VStack(alignment: .leading, spacing: 8) {
				Text(Strings.Onboarding.Household.heading)
					.font(NurturTypography.title2)
					.foregroundStyle(NurturColors.textPrimary)
				Text(Strings.Onboarding.Household.subheading)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}
			
			GlassEffectContainer {
				VStack(spacing: 12) {
					ForEach(HouseholdType.allCases, id: \.self) { selectedAnswer in
						HouseholdTypeOptionRow(
							label: selectedAnswer.displayName,
							isSelected: stepState == selectedAnswer
						) {
							stepState = selectedAnswer
						}
					}
				}
			}
			.sensoryFeedback(.selection, trigger: stepState)
		}
	}
}

// MARK: - Option Row

private struct HouseholdTypeOptionRow: View {
	let label: String
	let isSelected: Bool
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Text(label)
					.font(NurturTypography.headline)
					.foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
				Spacer()
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.font(.system(size: 20, weight: .semibold))
					.foregroundStyle(isSelected ? .white : NurturColors.textFaint.opacity(0.45))
					.contentTransition(.symbolEffect(.replace))
			}
			.padding(.horizontal, 18)
			.padding(.vertical, 16)
			.contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			.glassEffect(
				isSelected
					? .regular.tint(NurturColors.accent).interactive()
					: .regular.interactive(),
				in: .rect(cornerRadius: 18, style: .continuous)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.strokeBorder(
						isSelected
							? AnyShapeStyle(Color.white.opacity(0.35))
							: AnyShapeStyle(NurturGradients.glassRim),
						lineWidth: 1
					)
			)
			.shadow(
				color: isSelected ? NurturColors.accent.opacity(0.25) : .black.opacity(0.05),
				radius: isSelected ? 12 : 8,
				x: 0,
				y: isSelected ? 6 : 4
			)
		}
		.buttonStyle(.plain)
		.nurturPressable()
		.animation(NurturMotion.spring, value: isSelected)
	}
}
