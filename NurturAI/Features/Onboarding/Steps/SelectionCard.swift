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
			.contentShape(RoundedRectangle(cornerRadius: 14))
            .glassEffect(
                isSelected
                    ? .regular.tint(NurturColors.accent).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.75), location: 0),
                                    .init(color: NurturColors.accent.opacity(0.20), location: 0.5),
                                    .init(color: .white.opacity(0.35), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(NurturGradients.glassRim),
                        lineWidth: isSelected ? 1.2 : 0.8
                    )
            )
            .shadow(
                color: isSelected ? NurturColors.accent.opacity(0.30) : .black.opacity(0.06),
                radius: isSelected ? 12 : 8,
                x: 0,
                y: isSelected ? 6 : 4
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(NurturColors.accent)
                        .background(Circle().fill(.white))
                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                        .padding(6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(NurturMotion.spring, value: isSelected)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

#Preview("SelectionCard") {
	SelectionCard(icon: "moon.zzz.fill", label: "Testing", isSelected: false, action: { print("fired") })
}
