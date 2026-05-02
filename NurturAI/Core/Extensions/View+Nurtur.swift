import SwiftUI

extension View {

    func nurturCard() -> some View {
        self
            .background(NurturColors.surface, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    func nurturCardPadded() -> some View {
        self
            .padding(16)
            .nurturCard()
    }

    func pillButton(isSelected: Bool = false) -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected ? NurturColors.accent : NurturColors.surfaceWarm,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
            .font(NurturTypography.subheadline)
    }

    func errorAlert(error: Binding<AppError?>) -> some View {
        self.alert(Strings.Common.somethingWrong, isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            Button(Strings.Common.ok, role: .cancel) {}
        } message: {
            if let err = error.wrappedValue {
                Text(err.errorDescription ?? Strings.Common.unknownError)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = NurturColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .font(NurturTypography.headline)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
