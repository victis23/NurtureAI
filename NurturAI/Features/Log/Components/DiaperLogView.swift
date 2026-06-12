import SwiftUI

struct DiaperLogView: View {
    @Bindable var viewModel: QuickLogViewModel
	@Environment(\.appContainer) private var container

    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    GlassIconBadge(icon: "bubbles.and.sparkles", color: NurturColors.success, size: 30)
                    Text(Strings.Log.Diaper.typeLabel)
                        .font(NurturTypography.headline)
                        .foregroundStyle(NurturColors.textPrimary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(DiaperType.allCases, id: \.self) { type in
                        let isSelected = viewModel.selectedDiaperType == type
                        Button {
                            viewModel.selectedDiaperType = type
                        } label: {
                            Text(type.rawValue.capitalized)
                                .font(NurturTypography.subheadline)
                                .fontWeight(isSelected ? .bold : .medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
                                .modifier(SelectionChipBackground(isSelected: isSelected, color: NurturColors.success))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(Strings.Common.logNow) {
                Task { await viewModel.logDiaper(baby: baby) }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .animation(NurturMotion.spring, value: viewModel.selectedDiaperType)
        .sensoryFeedback(.selection, trigger: viewModel.selectedDiaperType)
		.onAppear {
			container?.analyticsService.logPageView("diaperLogView")
		}
    }
}
