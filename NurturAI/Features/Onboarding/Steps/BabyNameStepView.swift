import SwiftUI

struct BabyNameStepView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
                .textContentType(.name)
                .submitLabel(.continue)
                .focused($isFocused)
                .padding(16)
                .background(NurturColors.surfaceWarm, in: RoundedRectangle(cornerRadius: 14))
			
			Spacer()
			
			VStack {
				Text(Strings.Onboarding.Greeting.greeting2)
					.multilineTextAlignment(.center)
					.font(NurturTypography.bodyMedium)
					.lineSpacing(10)
					.fontWeight(.light)
					.foregroundStyle(.black.opacity(0.7))
					.padding(10)
			}
			.background(
				.ultraThinMaterial
					.opacity(0.5)
					.shadow(.drop(radius: 3)),
				in: RoundedRectangle(cornerRadius: 15)
			)
			.background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
        }
        .onAppear { isFocused = true }
    }
}
