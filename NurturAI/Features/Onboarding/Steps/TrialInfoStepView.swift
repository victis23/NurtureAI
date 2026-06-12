import SwiftUI

struct TrialInfoStepView: View {
    @State private var cardsAppeared: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.TrialInfo.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.TrialInfo.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            GlassEffectContainer {
                VStack(spacing: 12) {
                    TrialInfoCard(
                        icon: "calendar.badge.clock",
                        title: Strings.Onboarding.TrialInfo.trialTitle,
                        textBody: Strings.Onboarding.TrialInfo.trialBody,
                        delay: 0.05
                    )
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 16)

                    TrialInfoCard(
                        icon: "bell.badge",
                        title: Strings.Onboarding.TrialInfo.reminderTitle,
                        textBody: Strings.Onboarding.TrialInfo.reminderBody,
                        delay: 0.15
                    )
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 16)

                    TrialInfoCard(
                        icon: "checkmark.shield",
                        title: Strings.Onboarding.TrialInfo.cancelTitle,
                        textBody: Strings.Onboarding.TrialInfo.cancelBody,
                        delay: 0.25
                    )
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 16)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(NurturColors.accent)
                    .padding(.top, 2)
                Text(Strings.Onboarding.TrialInfo.reassurance)
                    .font(NurturTypography.callout)
                    .foregroundStyle(NurturColors.textPrimary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 16)
            .nurturGlassCardTinted(NurturColors.accent, cornerRadius: 22)
        }
        .onAppear {
            withAnimation(NurturMotion.gentle) {
                cardsAppeared = true
            }
        }
    }
}

private struct TrialInfoCard: View {
    let icon: String
    let title: String
    let textBody: String
    let delay: Double

    @State private var appeared: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GlassIconBadge(icon: icon, color: NurturColors.accent, size: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(textBody)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .nurturGlassCard(cornerRadius: 22)
        .onAppear {
            withAnimation(NurturMotion.gentle.delay(delay)) {
                appeared = true
            }
        }
    }
}
