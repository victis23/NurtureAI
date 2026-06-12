import SwiftUI

extension View {

    func nurturCard() -> some View {
        self.nurturGlassCard(cornerRadius: 20)
    }

    func nurturCardPadded() -> some View {
        self
            .padding(16)
            .nurturCard()
    }

    @ViewBuilder
    func pillButton(isSelected: Bool = false) -> some View {
        let label = self
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .font(NurturTypography.subheadline)
        if isSelected {
            label
                .background(NurturGradients.accent, in: Capsule())
                .foregroundStyle(.white)
                .shadow(color: NurturColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        } else {
            label
                .foregroundStyle(NurturColors.textPrimary)
                .nurturGlassPill()
        }
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

	func onboardingText() -> some View {
		VStack {
			self
				.multilineTextAlignment(.center)
				.font(NurturTypography.bodyMedium)
				.lineSpacing(10)
				.fontWeight(.light)
				.foregroundStyle(.black.opacity(0.7))
				.padding(10)
		}
		.background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
		.nurturGlassCard(cornerRadius: 18)
	}
}

struct PrimaryButtonStyle: ButtonStyle {
	@Environment(\.isEnabled) var isEnabled
    var tint: Color = NurturColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isEnabled
                    ? AnyShapeStyle(LinearGradient(
                        colors: [tint, tint.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(Color.disbledAccentOrange),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(NurturGradients.glassRim, lineWidth: 1)
            )
            .foregroundStyle(.white)
            .font(NurturTypography.headline)
            .shadow(color: isEnabled ? tint.opacity(0.32) : .clear, radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(NurturMotion.snappy, value: configuration.isPressed)
            .animation(.easeOut, value: isEnabled)
    }
}
