import SwiftUI

struct EscalationBannerView: View {
    let isEmergency: Bool
    let callDoctorItems: [String]

    var body: some View {
        if isEmergency {
            emergencyBanner
        } else if !callDoctorItems.isEmpty {
            doctorBanner
        }
    }

    private var emergencyBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                GlassIconBadge(icon: "exclamationmark.triangle.fill", color: NurturColors.danger, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Assist.Escalation.emergencyHeading)
                        .font(NurturTypography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(NurturColors.danger)
                    Text(Strings.Assist.Escalation.emergencySubheading)
                        .font(NurturTypography.subheadline)
                        .foregroundStyle(NurturColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .nurturGlassCardTinted(NurturColors.danger, cornerRadius: 22)
    }

    private var doctorBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                GlassIconBadge(icon: "stethoscope", color: NurturColors.warning, size: 30)
                Text(Strings.Assist.Escalation.doctorHeading)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(callDoctorItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(item)
                    }
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .nurturGlassCardTinted(NurturColors.warning, cornerRadius: 22)
    }
}
