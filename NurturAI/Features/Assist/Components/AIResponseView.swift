import SwiftUI

struct AIResponseView: View {
    let response: AIResponse
    /// Current feedback state for this response: `nil` = not yet rated,
    /// `true` = thumbs-up, `false` = thumbs-down.
    let wasHelpful: Bool?
    /// Invoked once when the parent taps a thumb. Caller is responsible for
    /// persisting the choice; the view just reflects whatever `wasHelpful`
    /// becomes after the tap propagates back.
    let onFeedback: ((Bool) -> Void)?

    private var isOffTopic: Bool {
        response.causes.isEmpty && response.confidence == 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reassurance — also serves as the off-topic reply.
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(NurturColors.accent)
                    .padding(.top, 1)
                Text(response.reassurance)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(NurturColors.accentSoft, in: RoundedRectangle(cornerRadius: 14))

            if !isOffTopic {
                // Confidence note
                if response.confidence < 40 {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(NurturColors.textFaint)
                        Text(Strings.Assist.Response.lowConfidenceNote)
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textFaint)
                    }
                }

                // Cause cards
                ForEach(response.causes) { cause in
                    CauseCardView(cause: cause)
                }

                // Escalation banner
                if !response.escalation.callDoctor.isEmpty || !response.escalation.er.isEmpty {
                    EscalationBannerView(
                        isEmergency: !response.escalation.er.isEmpty,
                        callDoctorItems: response.escalation.callDoctor
                    )
                }

                // Monitor items
                if !response.escalation.monitor.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Strings.Assist.Response.monitorHeading)
                            .font(NurturTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(NurturColors.textPrimary)
                        ForEach(response.escalation.monitor, id: \.self) { item in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text(item)
                            }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.textSecondary)
                        }
                    }
                    .padding(14)
                    .background(NurturColors.surfaceWarm, in: RoundedRectangle(cornerRadius: 12))
                }

                // Follow-up
                if let followUp = response.followUp {
                    Text(followUp)
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textFaint)
                        .italic()
                }

                // Single feedback row at the bottom of the response.
                if let onFeedback {
                    FeedbackRow(wasHelpful: wasHelpful, onFeedback: onFeedback)
                }
            }
        }
    }
}

/// Tiny acknowledgement row for thumbs-up / thumbs-down. Once a choice is
/// made the chosen icon fills in (semantic color), the other dims, and the
/// prompt swaps to a thank-you. Both buttons disable post-selection so the
/// rating can't accidentally flip.
private struct FeedbackRow: View {
    let wasHelpful: Bool?
    let onFeedback: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Spacer()
            Text(wasHelpful == nil ? Strings.Assist.Feedback.prompt : Strings.Assist.Feedback.thanks)
                .font(NurturTypography.caption)
                .foregroundStyle(NurturColors.textFaint)

            Button {
                guard wasHelpful == nil else { return }
                onFeedback(true)
            } label: {
                Image(systemName: wasHelpful == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.subheadline)
                    .foregroundStyle(thumbColor(for: true))
                    .symbolEffect(.bounce, value: wasHelpful == true)
            }
            .disabled(wasHelpful != nil)

            Button {
                guard wasHelpful == nil else { return }
                onFeedback(false)
            } label: {
                Image(systemName: wasHelpful == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.subheadline)
                    .foregroundStyle(thumbColor(for: false))
                    .symbolEffect(.bounce, value: wasHelpful == false)
            }
            .disabled(wasHelpful != nil)
        }
        .animation(.easeInOut(duration: 0.2), value: wasHelpful)
    }

    private func thumbColor(for positive: Bool) -> Color {
        switch wasHelpful {
        case .some(let chosen) where chosen == positive:
            return positive ? NurturColors.success : NurturColors.danger
        case .some:
            return NurturColors.textFaint.opacity(0.4)
        case .none:
            return NurturColors.textSecondary
        }
    }
}
