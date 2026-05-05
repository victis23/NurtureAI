import SwiftUI

struct CauseCardView: View {
    let cause: AICause

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header — label + percentage
            HStack(alignment: .firstTextBaseline) {
                Text(cause.label)
                    .font(NurturTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textPrimary)
                Spacer()
                Text("\(Int(cause.probability))%")
                    .font(NurturTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(probabilityColor)
                    .monospacedDigit()
            }

            // Full-width probability bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(probabilityColor.opacity(0.18))
                    Capsule()
                        .fill(probabilityColor)
                        .frame(width: max(0, geo.size.width * CGFloat(cause.probability) / 100.0))
                }
            }
            .frame(height: 6)

            // Reasoning
            Text(cause.reasoning)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)

            // Actions — soft circular bullets in the probability tint
            if !cause.actions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cause.actions, id: \.self) { action in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(probabilityColor.opacity(0.25))
                                .overlay(
                                    Circle().strokeBorder(probabilityColor.opacity(0.55), lineWidth: 1)
                                )
                                .frame(width: 7, height: 7)
                                .padding(.top, 7)
                            Text(action)
                                .font(NurturTypography.subheadline)
                                .foregroundStyle(NurturColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(probabilityColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(probabilityColor.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private var probabilityColor: Color {
        if cause.probability >= 60 { return NurturColors.success }
        if cause.probability >= 30 { return NurturColors.warning }
        return NurturColors.info
    }
}
