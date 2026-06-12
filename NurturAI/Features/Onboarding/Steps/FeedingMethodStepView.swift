import SwiftUI

struct FeedingMethodStepView: View {
    @Binding var feedingMethod: FeedingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Feeding.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Feeding.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            GlassEffectContainer {
                VStack(spacing: 12) {
                    ForEach(FeedingMethod.allCases, id: \.self) { method in
                        Button {
                            feedingMethod = method
                        } label: {
                            HStack(spacing: 12) {
                                Text(method.displayName)
                                    .font(NurturTypography.headline)
                                Spacer()
                                if feedingMethod == method {
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
                                feedingMethod == method
                                    ? .regular.tint(NurturColors.accent).interactive()
                                    : .regular.interactive(),
                                in: .rect(cornerRadius: 18, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(
                                        feedingMethod == method
                                            ? AnyShapeStyle(Color.white.opacity(0.35))
                                            : AnyShapeStyle(NurturGradients.glassRim),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(
                                color: feedingMethod == method
                                    ? NurturColors.accent.opacity(0.25)
                                    : .black.opacity(0.05),
                                radius: 10, x: 0, y: 5
                            )
                            .foregroundStyle(feedingMethod == method ? .white : NurturColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(NurturMotion.spring, value: feedingMethod)
            }
            .sensoryFeedback(.selection, trigger: feedingMethod)
        }
    }
}
