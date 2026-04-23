import SwiftUI

struct FeedingMethodStepView: View {
    @Binding var feedingMethod: FeedingMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Feeding.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Feeding.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(FeedingMethod.allCases, id: \.self) { method in
                    Button {
                        feedingMethod = method
                    } label: {
                        HStack {
                            Text(method.displayName)
                                .font(NurturTypography.headline)
                            Spacer()
                            if feedingMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NurturColors.accent)
                            }
                        }
                        .padding(18)
                        .background(
                            feedingMethod == method ? NurturColors.accentSoft : NurturColors.surfaceWarm,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(feedingMethod == method ? NurturColors.accent : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(NurturColors.textPrimary)
                    }
                }
            }
        }
    }
}
