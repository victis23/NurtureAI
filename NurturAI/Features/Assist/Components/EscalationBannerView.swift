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
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Assist.Escalation.emergencyHeading)
                        .font(NurturTypography.headline)
                        .fontWeight(.bold)
                    Text(Strings.Assist.Escalation.emergencySubheading)
                        .font(NurturTypography.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NurturColors.danger, in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(.white)
    }

    private var doctorBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "stethoscope")
                    .foregroundStyle(NurturColors.warning)
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
        .padding(14)
        .background(NurturColors.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(NurturColors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}
