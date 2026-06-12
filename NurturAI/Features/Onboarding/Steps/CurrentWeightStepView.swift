import SwiftUI

struct CurrentWeightStepView: View {
    @Binding var grams: Int

    @State private var pounds: Int = 0
    @State private var ounces: Int = 0

    private static let gramsPerPound: Double = 453.592
    private static let gramsPerOunce: Double = 28.3495

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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

/// Shared lb/oz wheel picker used by both weight steps. The big two-column
/// readout (pounds + ounces with unit labels) is the focal point; the wheel
/// pickers below drive it. Background is Liquid Glass with selection haptics
/// on each wheel turn.
///
/// Pounds range covers 0–40 lb so the same picker works for newborn weights
/// and the toddler-stage current-weight check-ins.
struct WeightWheelPicker: View {
    @Binding var pounds: Int
    @Binding var ounces: Int
    let grams: Int

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 28) {
                    readoutColumn(value: pounds, unit: Strings.Common.unitPounds)
                    readoutColumn(value: ounces, unit: Strings.Common.unitOunces)
                }
                Text(grams > 0 ? Strings.Onboarding.Weight.gramsApprox(grams) : Strings.Common.tapToSet)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 0) {
                Picker(Strings.Onboarding.Weight.poundsPicker, selection: $pounds) {
                    ForEach(0..<41, id: \.self) { value in
                        Text(Strings.Onboarding.Weight.pounds(value))
                            .foregroundStyle(NurturColors.textPrimary)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                Picker(Strings.Onboarding.Weight.ouncesPicker, selection: $ounces) {
                    ForEach(0..<16, id: \.self) { value in
                        Text(Strings.Onboarding.Weight.ounces(value))
                            .foregroundStyle(NurturColors.textPrimary)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 180)
            .tint(NurturColors.accent)
        }
        .padding(20)
        .nurturGlassCard(cornerRadius: 24)
        .sensoryFeedback(.selection, trigger: pounds)
        .sensoryFeedback(.selection, trigger: ounces)
    }

    private func readoutColumn(value: Int, unit: String) -> some View {
        VStack(spacing: 0) {
            Text("\(value)")
                .font(NurturTypography.title)
                .foregroundStyle(NurturColors.accent)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
            Text(unit)
                .font(NurturTypography.caption2)
                .foregroundStyle(NurturColors.textFaint)
                .textCase(.uppercase)
                .tracking(1.2)
        }
    }
}
