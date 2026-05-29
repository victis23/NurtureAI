import SwiftUI
import Combine

struct FeedTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
	@Environment(\.appContainer) private var container

    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            // Side picker
            VStack(alignment: .leading, spacing: 14) {
                Text(Strings.Log.Feed.sideLabel)
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)
                HStack(spacing: 10) {
                    ForEach(FeedSide.allCases, id: \.self) { side in
                        let isSelected = viewModel.feedSide == side
                        Button {
                            viewModel.feedSide = side
                        } label: {
                            Text(side.rawValue.capitalized)
                                .font(NurturTypography.subheadline)
                                .fontWeight(isSelected ? .bold : .medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
                                .modifier(SelectionChipBackground(isSelected: isSelected, color: NurturColors.info, cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.feedSide)
            .sensoryFeedback(.selection, trigger: viewModel.feedSide)

            // Tappable circular timer (start / stop)
            CircularTimerButton(
                startTime: viewModel.feedStartTime,
                isRunning: viewModel.isFeedTimerRunning,
                color: NurturColors.info,
                runningLabel: Strings.Log.Feed.inProgress,
                idleLabel: Strings.Log.Feed.readyToStart
            ) {
                if viewModel.isFeedTimerRunning {
                    Task { await viewModel.stopFeed(baby: baby) }
                } else {
                    viewModel.startFeed()
                }
            }
            .padding(.vertical, 8)

            // Bottle amount (optional)
            if viewModel.feedSide == .bottle {
                HStack {
                    Text(Strings.Log.Feed.amountLabel)
                        .font(NurturTypography.subheadline)
                        .foregroundStyle(NurturColors.textSecondary)
                    Spacer()
                    Stepper(
                        value: Binding(
                            get: { viewModel.bottleML ?? 0 },
                            set: { viewModel.bottleML = $0 > 0 ? $0 : nil }
                        ),
                        in: 0...500,
                        step: 10
                    ) {
                        Text(viewModel.bottleML.map { "\($0) ml" } ?? "—")
                            .font(NurturTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(NurturColors.textPrimary)
                    }
                }
                .padding(14)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.feedSide == .bottle)
        .onAppear {
			container?.analyticsService.logPageView("feedTimerView")
        }
    }
}
