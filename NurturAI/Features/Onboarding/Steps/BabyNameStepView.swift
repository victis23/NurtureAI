import SwiftUI

struct BabyNameStepView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Name.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Name.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            TextField(Strings.Onboarding.Name.placeholder, text: $name)
                .font(NurturTypography.title3)
                .foregroundStyle(NurturColors.textPrimary)
                .tint(NurturColors.accent)
                .textContentType(.name)
                .submitLabel(.continue)
                .focused($isFocused)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .nurturGlassCard(cornerRadius: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(NurturColors.accent.opacity(isFocused ? 0.45 : 0), lineWidth: 1.5)
                )
                .animation(NurturMotion.spring, value: isFocused)
			
			Spacer()
			
			VStack {
				Text(Strings.Onboarding.Greeting.greeting2)
					.onboardingText()
			}
        }
        .onAppear { isFocused = true }
    }
}
