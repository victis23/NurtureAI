import SwiftUI

struct BabyBirthdayStepView: View {
    @Binding var birthDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.Birthday.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.Birthday.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            // Live readout above the calendar — the graphical DatePicker lets
            // users tap into separate month/year scrubbers, and it's easy to
            // change one without confirming a day. Echoing the full selection
            // up here makes the chosen date impossible to miss.
            dateReadout

            DatePicker(
                Strings.Onboarding.Birthday.pickerLabel,
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(NurturColors.accent)
            .labelsHidden()
            .padding(12)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Readout

    private var dateReadout: some View {
        VStack(spacing: 4) {
            Text(primaryLine)
                .font(NurturTypography.title2)
                .foregroundStyle(NurturColors.accent)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(.snappy, value: birthDate)
            Text(secondaryLine)
                .font(NurturTypography.caption)
                .foregroundStyle(NurturColors.textFaint)
                .contentTransition(.opacity)
                .animation(.snappy, value: birthDate)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .glassEffect(
            .regular.tint(NurturColors.accent.opacity(0.35)),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private var primaryLine: String {
        birthDate.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var secondaryLine: String {
        let year = birthDate.formatted(.dateTime.year())
        return "\(year) • \(ageDescription)"
    }

    private var ageDescription: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: birthDate, to: .now).day ?? 0

        if days < 0 { return "due soon" }
        if days == 0 { return "born today" }
        if days < 7 {
            return "\(days) day\(days == 1 ? "" : "s") old"
        }

        let weeks = cal.dateComponents([.weekOfYear], from: birthDate, to: .now).weekOfYear ?? 0
        if weeks < 16 {
            return "\(weeks) week\(weeks == 1 ? "" : "s") old"
        }

        let months = cal.dateComponents([.month], from: birthDate, to: .now).month ?? 0
        if months < 24 {
            return "\(months) month\(months == 1 ? "" : "s") old"
        }

        let years = cal.dateComponents([.year], from: birthDate, to: .now).year ?? 0
        return "\(years) year\(years == 1 ? "" : "s") old"
    }
}
