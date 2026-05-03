import SwiftUI

struct ChildcareChallengeStepView: View {
    @Binding var selection: Set<ChildcareChallenge>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Challenges.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Challenges.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                Text(Strings.Onboarding.Challenges.multiSelectHint)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
                    .padding(.top, 4)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ChildcareChallenge.allCases, id: \.self) { challenge in
                    SelectionCard(
                        icon: icon(for: challenge),
                        label: challenge.displayName,
                        isSelected: selection.contains(challenge)
                    ) {
                        toggle(challenge)
                    }
                }
            }
        }
    }

    private func toggle(_ challenge: ChildcareChallenge) {
        if selection.contains(challenge) {
            selection.remove(challenge)
        } else {
            selection.insert(challenge)
        }
    }

    private func icon(for challenge: ChildcareChallenge) -> String {
        switch challenge {
        case .feeding:      return "fork.knife"
        case .sleeping:     return "moon.zzz.fill"
        case .diapering:    return "drop.fill"
        case .soothing:     return "heart.fill"
        case .selfCare:     return "leaf.fill"
        case .allOfIt:      return "infinity"
        }
    }
}
