import SwiftUI
import Combine

struct FeedTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
	@Environment(\.appContainer) private var container

    let baby: Baby
    @State private var elapsed: TimeInterval = 0
	let feedTimerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

            // Timer display with breathing halo
            TimerHalo(isRunning: viewModel.isFeedTimerRunning, color: NurturColors.info) {
                VStack(spacing: 8) {
                    TimerDisplay(elapsed: elapsed, isRunning: viewModel.isFeedTimerRunning)
                    Text(viewModel.isFeedTimerRunning ? Strings.Log.Feed.inProgress : Strings.Log.Feed.readyToStart)
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textFaint)
                }
            }
            .padding(.vertical, 8)

            // Start / Stop button
            Button {
                if viewModel.isFeedTimerRunning {
                    Task { await viewModel.stopFeed(baby: baby) }
                } else {
                    viewModel.startFeed()
                }
            } label: {
                Text(viewModel.isFeedTimerRunning ? Strings.Log.Feed.stopFeed : Strings.Log.Feed.startFeed)
            }
            .buttonStyle(PrimaryButtonStyle(tint: viewModel.isFeedTimerRunning ? NurturColors.danger : NurturColors.accent))

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
        .onReceive(feedTimerPublisher) { _ in
            if let start = viewModel.feedStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
        }
        .onAppear {
            if let start = viewModel.feedStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
			container?.analyticsService.logPageView("feedTimerView")
        }
    }
}
