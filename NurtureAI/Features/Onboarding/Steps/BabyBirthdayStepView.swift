import SwiftUI

struct BabyBirthdayStepView: View {
    @Binding var birthDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("When was your baby born?")
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text("We use this to personalise advice for their age and stage.")
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            DatePicker(
                "Date of birth",
                selection: $birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(NurturColors.accent)
        }
    }
}
