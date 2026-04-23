import SwiftUI

struct CauseCardView: View {
    let cause: AICause
    let onFeedback: ((Bool) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Probability bar + label
            HStack(alignment: .center, spacing: 10) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(NurturColors.surfaceWarm)
                        .frame(height: 6)
                    Capsule()
                        .fill(probabilityColor)
                        .frame(width: probabilityBarWidth, height: 6)
                }
                .frame(width: 80)

                Text(cause.label)
                    .font(NurturTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textPrimary)

                Spacer()

                Text("\(Int(cause.probability))%")
                    .font(NurturTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(probabilityColor)
            }

            // Reasoning
            Text(cause.reasoning)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)

            // Actions
            if !cause.actions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(cause.actions, id: \.self) { action in
                        HStack(alignment: .top, spacing: 6) {
                            Text("→")
                                .foregroundStyle(NurturColors.accent)
                            Text(action)
                                .foregroundStyle(NurturColors.textPrimary)
                        }
                        .font(NurturTypography.subheadline)
                    }
                }
            }

            // Feedback buttons
            if let onFeedback {
                HStack(spacing: 12) {
                    Spacer()
                    Text("Did this help?")
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textFaint)
                    Button {
                        onFeedback(true)
                    } label: {
                        Image(systemName: "hand.thumbsup")
                            .font(.caption)
                            .foregroundStyle(NurturColors.success)
                    }
                    Button {
                        onFeedback(false)
                    } label: {
                        Image(systemName: "hand.thumbsdown")
                            .font(.caption)
                            .foregroundStyle(NurturColors.danger)
                    }
                }
            }
        }
        .nurturCardPadded()
    }

    private var probabilityColor: Color {
        if cause.probability >= 60 { return NurturColors.success }
        if cause.probability >= 30 { return NurturColors.warning }
        return NurturColors.textFaint
    }

    private var probabilityBarWidth: CGFloat {
        CGFloat(cause.probability) / 100.0 * 80
    }
}
