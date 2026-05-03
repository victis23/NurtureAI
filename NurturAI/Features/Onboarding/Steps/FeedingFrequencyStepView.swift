import SwiftUI

struct FeedingFrequencyStepView: View {
    @Binding var stepState: FeedingFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.FeedingFreq.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.FeedingFreq.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(FeedingFrequency.allCases, id: \.self) { selectedAnswer in
                    Button {
                        stepState = selectedAnswer
                    } label: {
                        HStack {
                            Text(selectedAnswer.displayName)
                                .font(NurturTypography.headline)
                            Spacer()
                            if stepState == selectedAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NurturColors.accent)
                            }
                        }
                        .padding(18)
                        .background(
                            stepState == selectedAnswer ? NurturColors.accentSoft : NurturColors.surfaceWarm,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(stepState == selectedAnswer ? NurturColors.accent : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(NurturColors.textPrimary)
                    }
                }
            }
        }
    }
}
