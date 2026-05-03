import SwiftUI
import Combine

struct FeedTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby
    @State private var elapsed: TimeInterval = 0
	let feedTimerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            // Side picker
            VStack(alignment: .leading, spacing: 10) {
                Text(Strings.Log.Feed.sideLabel)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                HStack(spacing: 10) {
                    ForEach(FeedSide.allCases, id: \.self) { side in
                        PillButton(title: side.rawValue.capitalized, isSelected: viewModel.feedSide == side) {
                            viewModel.feedSide = side
                        }
                    }
                }
            }

            // Timer display
            VStack(spacing: 8) {
                TimerDisplay(elapsed: elapsed, isRunning: viewModel.isFeedTimerRunning)
                Text(viewModel.isFeedTimerRunning ? Strings.Log.Feed.inProgress : Strings.Log.Feed.readyToStart)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }

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
                    }
                }
                .padding(14)
                .background(NurturColors.surfaceWarm, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onReceive(feedTimerPublisher) { _ in
            if let start = viewModel.feedStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
        }
        .onAppear {
            if let start = viewModel.feedStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
        }
    }
}
