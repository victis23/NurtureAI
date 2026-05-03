import SwiftUI

struct CurrentWeightStepView: View {
    @Binding var grams: Int

    @State private var pounds: Int = 0
    @State private var ounces: Int = 0

    private static let gramsPerPound: Double = 453.592
    private static let gramsPerOunce: Double = 28.3495

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.CurrentWeight.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.CurrentWeight.subheading)
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

/// Shared lb/oz wheel picker used by both weight steps. Shows a large lb/oz
/// readout (and approximate grams) above two wheel pickers so the value the
/// parent is dialing in stays the focal point.
struct WeightWheelPicker: View {
    @Binding var pounds: Int
    @Binding var ounces: Int
    let grams: Int

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(pounds) lb \(ounces) oz")
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.accent)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: pounds)
                    .animation(.snappy, value: ounces)
                Text(grams > 0 ? "≈ \(grams) g" : "Tap to set")
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }

            HStack(spacing: 0) {
                Picker("Pounds", selection: $pounds) {
                    ForEach(0..<16, id: \.self) { Text("\($0) lb").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker("Ounces", selection: $ounces) {
                    ForEach(0..<16, id: \.self) { Text("\($0) oz").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 180)
        }
        .padding(18)
        .background(NurturColors.surfaceWarm, in: RoundedRectangle(cornerRadius: 14))
    }
}
