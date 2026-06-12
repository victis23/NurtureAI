import SwiftUI

struct DesiredFeaturesStepView: View {
    @Binding var selection: Set<DesiredFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Features.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Features.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(NurturColors.accent)
                    Text(Strings.Onboarding.Features.multiSelectHint)
                        .font(NurturTypography.captionMedium)
                        .foregroundStyle(NurturColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .nurturGlassPill()
                .padding(.top, 4)
            }

            GlassEffectContainer {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(DesiredFeature.allCases, id: \.self) { feature in
                        SelectionCard(
                            icon: icon(for: feature),
                            label: feature.displayName,
                            isSelected: selection.contains(feature)
                        ) {
                            toggle(feature)
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ feature: DesiredFeature) {
        if selection.contains(feature) {
            selection.remove(feature)
        } else {
            selection.insert(feature)
        }
    }

    private func icon(for feature: DesiredFeature) -> String {
        switch feature {
        case .sleepTracking:    return "moon.zzz.fill"
        case .feedingTracking:  return "fork.knife"
        case .aiAdvice:         return "sparkles"
        case .milestones:       return "flag.fill"
        case .growthTracking:   return "chart.line.uptrend.xyaxis"
        case .diaperTracking:   return "drop.fill"
        case .communitySupport: return "person.2.fill"
        }
    }
}
