import SwiftUI
import Combine

struct SleepTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
	@Environment(\.appContainer) private var container

    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            CircularTimerButton(
                startTime: viewModel.sleepStartTime,
                isRunning: viewModel.isSleepTimerRunning,
                color: NurturColors.accent,
                runningLabel: Strings.Log.Sleep.inProgress,
                idleLabel: Strings.Log.Sleep.readyToStart
            ) {
                if viewModel.isSleepTimerRunning {
                    Task { await viewModel.stopSleep(baby: baby) }
                } else {
                    viewModel.startSleep()
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear {
			container?.analyticsService.logPageView("sleepTimerView")
        }
    }
}
