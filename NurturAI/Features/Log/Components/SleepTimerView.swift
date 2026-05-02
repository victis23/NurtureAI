import SwiftUI
import Combine

struct SleepTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby
    @State private var elapsed: TimeInterval = 0
	let sleepTimerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(NurturColors.accent)
                TimerDisplay(elapsed: elapsed, isRunning: viewModel.isSleepTimerRunning)
                Text(viewModel.isSleepTimerRunning ? Strings.Log.Sleep.inProgress : Strings.Log.Sleep.readyToStart)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }

            Button {
                if viewModel.isSleepTimerRunning {
                    Task { await viewModel.stopSleep(baby: baby) }
                } else {
                    viewModel.startSleep()
                }
            } label: {
                Text(viewModel.isSleepTimerRunning ? Strings.Log.Sleep.wakeUp : Strings.Log.Sleep.startSleep)
            }
            .buttonStyle(PrimaryButtonStyle(tint: viewModel.isSleepTimerRunning ? NurturColors.warning : NurturColors.accent))
        }
        .onReceive(sleepTimerPublisher) { _ in
            if let start = viewModel.sleepStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
        }
        .onAppear {
            if let start = viewModel.sleepStartTime {
                elapsed = Date().timeIntervalSince(start)
            }
        }
    }
}
