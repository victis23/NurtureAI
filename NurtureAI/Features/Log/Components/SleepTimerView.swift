import SwiftUI
import Combine

struct SleepTimerView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(NurturColors.accent)
                TimerDisplay(elapsed: elapsed, isRunning: viewModel.isSleepTimerRunning)
                Text(viewModel.isSleepTimerRunning ? "Sleep in progress" : "Ready to start")
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
                Text(viewModel.isSleepTimerRunning ? "Wake Up" : "Start Sleep")
                    .primaryButton()
            }
            .tint(viewModel.isSleepTimerRunning ? NurturColors.warning : NurturColors.accent)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
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
