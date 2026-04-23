import SwiftUI

struct AIResponseView: View {
    let response: AIResponse
    let insight: AIInsight?
    let insightRepository: InsightRepositoryProtocol?

    private var isOffTopic: Bool {
        response.causes.isEmpty && response.confidence == 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reassurance (also serves as the off-topic reply)
            Text(response.reassurance)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)
                .padding(14)
                .background(NurturColors.accentSoft, in: RoundedRectangle(cornerRadius: 12))

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
                    CauseCardView(cause: cause) { wasHelpful in
                        guard let insight, let repo = insightRepository else { return }
                        try? repo.updateFeedback(insight, wasHelpful: wasHelpful)
                    }
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
            }
        }
    }
}
