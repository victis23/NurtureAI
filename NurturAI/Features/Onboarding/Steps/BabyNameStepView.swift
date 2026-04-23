import SwiftUI

struct BabyNameStepView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your baby's name?")
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text("You can always change this later.")
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            TextField("Baby's name", text: $name)
                .font(NurturTypography.title3)
                .textContentType(.name)
                .submitLabel(.continue)
                .focused($isFocused)
                .padding(16)
                .background(NurturColors.surfaceWarm, in: RoundedRectangle(cornerRadius: 14))
        }
        .onAppear { isFocused = true }
    }
}
