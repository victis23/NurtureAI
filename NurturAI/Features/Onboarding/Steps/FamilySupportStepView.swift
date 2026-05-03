//
//  FamilySupportStepView.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/3/26.
//


//
//  FirstChild.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/2/26.
//

import SwiftUI

struct FamilySupportStepView: View {
	@Binding var familySupport: FamilySupport
	
	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			VStack(alignment: .leading, spacing: 8) {
				Text(Strings.Onboarding.Support.heading)
					.font(NurturTypography.title2)
					.foregroundStyle(NurturColors.textPrimary)
				Text(Strings.Onboarding.Support.subheading)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}
			
			VStack(spacing: 12) {
				ForEach(FamilySupport.allCases, id: \.self) { hasSupport in
					Button {
						familySupport = hasSupport
					} label: {
						HStack {
							Text(hasSupport.displayName)
								.font(NurturTypography.headline)
							Spacer()
							if familySupport == hasSupport {
								Image(systemName: "checkmark.circle.fill")
									.foregroundStyle(.white)
							}
						}
						.padding(18)
						.glassEffect(
							familySupport == hasSupport
								? .regular.tint(NurturColors.accent).interactive()
								: .regular.interactive(),
							in: RoundedRectangle(cornerRadius: 14)
						)
						.foregroundStyle(familySupport == hasSupport ? .white : NurturColors.textPrimary)
					}
				}
			}
			.sensoryFeedback(.selection, trigger: familySupport)
		}
	}
}


struct FamilySupportpreview: PreviewProvider {
	static var previews: some View {
		FamilySupportStepView(familySupport: Binding(get: {
			FamilySupport.noSupport
		}, set: { _ in }))
	}
}
