import SwiftUI

struct AppDiscoveryStepView: View {
    @Binding var stepState: AppDiscoverySource

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.AppDiscovery.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.AppDiscovery.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(AppDiscoverySource.allCases, id: \.self) { selectedAnswer in
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
