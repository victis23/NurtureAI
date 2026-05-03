import SwiftUI

struct DiaperLogView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Log.Diaper.typeLabel)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(DiaperType.allCases, id: \.self) { type in
                        Button {
                            viewModel.selectedDiaperType = type
                        } label: {
                            Text(type.rawValue.capitalized)
                                .font(NurturTypography.subheadline)
                                .fontWeight(viewModel.selectedDiaperType == type ? .semibold : .regular)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    viewModel.selectedDiaperType == type ? NurturColors.accent : NurturColors.surfaceWarm,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(viewModel.selectedDiaperType == type ? .white : NurturColors.textPrimary)
                        }
                    }
                }
            }

            Button(Strings.Common.logNow) {
                Task { await viewModel.logDiaper(baby: baby) }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}
