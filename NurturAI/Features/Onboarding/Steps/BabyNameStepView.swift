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
        }
        .onAppear { isFocused = true }
    }
}
