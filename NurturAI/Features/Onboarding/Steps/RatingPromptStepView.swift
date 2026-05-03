import SwiftUI
import StoreKit

struct RatingPromptStepView: View {
    /// Called when the parent taps "Maybe later". Advances to the next
    /// onboarding step directly so users don't have to wrestle with the
    /// system rating sheet's Cancel/Not Now if it misbehaves — they always
    /// have a clear way forward from inside the app.
    let onSkip: () -> Void

    @Environment(\.requestReview) private var requestReview

    @State private var starsAppeared: Bool = false
    @State private var tapped: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Rating.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Rating.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            // Animated stars — staggered pop-in on first appear, draws the eye.
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { idx in
                    Image(systemName: "star.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(NurturColors.accent)
                        .scaleEffect(starsAppeared ? 1.0 : 0.5)
                        .opacity(starsAppeared ? 1.0 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(idx) * 0.08),
                            value: starsAppeared
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            // Encouragement block — reinforces the "why" before the ask.
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Onboarding.Rating.encourageTitle)
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Rating.encourageBody)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))

            // Primary action — accent-tinted glass, full-width, success haptic.
            Button {
                tapped.toggle()
                requestReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text(Strings.Onboarding.Rating.actionLabel)
                }
                .font(NurturTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .glassEffect(
                    .regular.tint(NurturColors.accent).interactive(),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: tapped)

            // Secondary action — explicit skip path. Sits below the primary in
            // a quieter visual weight (untinted glass, secondary text color)
            // so it never competes with the rating ask, but is always there
            // as an unambiguous way out.
//            Button {
//                onSkip()
//            } label: {
//                Text(Strings.Onboarding.Rating.skipLabel)
//                    .font(NurturTypography.subheadline)
//                    .foregroundStyle(NurturColors.textSecondary)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 12)
//                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
//            }
//            .buttonStyle(.plain)
        }
        .onAppear { starsAppeared = true }
    }
}
