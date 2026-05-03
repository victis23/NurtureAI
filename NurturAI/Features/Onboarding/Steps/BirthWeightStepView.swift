import SwiftUI

struct BirthWeightStepView: View {
    @Binding var grams: Int

    @State private var pounds: Int = 0
    @State private var ounces: Int = 0

    private static let gramsPerPound: Double = 453.592
    private static let gramsPerOunce: Double = 28.3495

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.BirthWeight.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.BirthWeight.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            WeightWheelPicker(pounds: $pounds, ounces: $ounces, grams: grams)
        }
        .onAppear { syncFromGrams() }
        .onChange(of: pounds) { _, _ in updateGrams() }
        .onChange(of: ounces) { _, _ in updateGrams() }
    }

    private func syncFromGrams() {
        guard grams > 0 else { return }
        let lbsTotal = Double(grams) / Self.gramsPerPound
        pounds = Int(lbsTotal)
        ounces = Int(((lbsTotal - Double(pounds)) * 16).rounded())
    }

    private func updateGrams() {
        grams = Int((Double(pounds) * Self.gramsPerPound + Double(ounces) * Self.gramsPerOunce).rounded())
    }
}
