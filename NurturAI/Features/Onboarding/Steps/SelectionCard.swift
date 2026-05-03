import SwiftUI

/// Reusable card used by multi-select onboarding steps. Renders an SF Symbol
/// + label inside a Liquid Glass surface that picks up an accent tint when
/// selected, with a checkmark badge in the corner.
struct SelectionCard: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? .white : NurturColors.textSecondary)
                    .frame(height: 24)
                Text(label)
                    .font(NurturTypography.footnote)
                    .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .glassEffect(
                isSelected
                    ? .regular.tint(NurturColors.accent).interactive()
                    : .regular.interactive(),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(NurturColors.accent)
                        .background(Circle().fill(NurturColors.surfaceWarm))
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
