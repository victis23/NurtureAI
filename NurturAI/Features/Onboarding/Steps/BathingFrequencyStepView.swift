import SwiftUI

struct BathingFrequencyStepView: View {
    @Binding var stepState: BathingFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Bathing.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Bathing.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            GlassEffectContainer {
                VStack(spacing: 12) {
                    ForEach(BathingFrequency.allCases, id: \.self) { selectedAnswer in
                        Button {
                            stepState = selectedAnswer
                        } label: {
                            HStack(spacing: 12) {
                                Text(selectedAnswer.displayName)
                                    .font(NurturTypography.headline)
                                Spacer()
                                if stepState == selectedAnswer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .glassEffect(
                                stepState == selectedAnswer
                                    ? .regular.tint(NurturColors.accent).interactive()
                                    : .regular.interactive(),
                                in: .rect(cornerRadius: 18, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(
                                        stepState == selectedAnswer
                                            ? AnyShapeStyle(Color.white.opacity(0.35))
                                            : AnyShapeStyle(NurturGradients.glassRim),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: stepState == selectedAnswer
                                    ? NurturColors.accent.opacity(0.25)
                                    : .black.opacity(0.05),
                                radius: 10, x: 0, y: 5
                            )
                            .foregroundStyle(stepState == selectedAnswer ? .white : NurturColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(NurturMotion.spring, value: stepState)
            }
            .sensoryFeedback(.selection, trigger: stepState)
        }
    }
}
