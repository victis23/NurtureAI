import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: HomeViewModel?

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    HomeContentView(viewModel: vm, baby: baby)
                } else if babies.isEmpty {
                    ContentUnavailableView(Strings.Common.noBabyProfile, systemImage: "sun.max")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.Home.navigationTitle)
			.task {
				guard let baby = babies.first, let container else { return }
				let vm = HomeViewModel(
					logRepository: container.logRepository,
					patternService: container.patternService,
					timerService: container.timerService
				)
				viewModel = vm
				await vm.load(baby: baby)
			}
    }
}

private struct HomeContentView: View {
    @Bindable var viewModel: HomeViewModel
    let baby: Baby
    @State private var showAssist: Bool = false
    @State private var assistQuery: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    BabyAvatar(name: baby.name, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(baby.name)
                            .font(NurturTypography.title3)
                            .foregroundStyle(NurturColors.textPrimary)
                        Text(baby.displayAge)
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(NurturColors.accentSoft, in: Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Active timer widget
                if let session = viewModel.activeTimerSession {
                    ActiveTimerWidget(session: session) {
                        Task { await viewModel.stopActiveTimer(baby: baby) }
                    }
                    .padding(.horizontal)
                }

                // Prediction card
                if let patterns = viewModel.patterns,
                   patterns.currentAwakeWindowMinutes > 0,
                   patterns.currentAwakeWindowMinutes >= patterns.ageAppropriateMaxAwakeMinutes - 15 {
                    PredictionCard(
                        title: Strings.Home.Prediction.title,
                        message: "\(baby.name) has been awake \(patterns.currentAwakeWindowMinutes) min — approaching the \(patterns.ageAppropriateMaxAwakeMinutes) min limit."
                    ) {
                        assistQuery = "\(baby.name) has been awake for \(patterns.currentAwakeWindowMinutes) minutes (max recommended is \(patterns.ageAppropriateMaxAwakeMinutes) min). What are some ways to help them wind down and fall asleep?"
                        showAssist = true
                    }
                    .padding(.horizontal)
                }

                // Status cards
                if let patterns = viewModel.patterns {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        NurturStatusCard(
                            title: Strings.Home.Status.lastFed,
                            value: patterns.lastFeedMinutesAgo.map { "\($0)m ago" } ?? Strings.Home.notLogged,
                            subtitle: patterns.feedingsToday > 0 ? "\(patterns.feedingsToday) \(Strings.Home.feedingsToday)" : nil,
                            icon: "drop.fill",
                            iconColor: NurturColors.info
                        )

                        NurturStatusCard(
                            title: Strings.Home.Status.awake,
                            value: "\(patterns.currentAwakeWindowMinutes)m",
                            subtitle: Strings.Home.Status.maxAwake("\(patterns.ageAppropriateMaxAwakeMinutes)"),
                            icon: "sun.max.fill",
                            iconColor: NurturColors.warning
                        )

                        NurturStatusCard(
                            title: Strings.Home.Status.sleepToday,
                            value: "\(patterns.totalSleepTodayMinutes / 60)h \(patterns.totalSleepTodayMinutes % 60)m",
                            icon: "moon.fill",
                            iconColor: NurturColors.accent
                        )

                        NurturStatusCard(
                            title: Strings.Home.Status.lastDiaper,
                            value: patterns.lastDiaperMinutesAgo.map { "\($0)m ago" } ?? Strings.Home.notLogged,
                            icon: "bubbles.and.sparkles",
                            iconColor: NurturColors.success
                        )
                    }
                    .padding(.horizontal)
                }

                // Quick-action row
                HStack(spacing: 12) {
                    LargeActionButton(title: Strings.Home.feed, icon: "drop.fill", color: NurturColors.info) {
                        viewModel.startFeed()
                    }
                    LargeActionButton(title: Strings.Home.sleep, icon: "moon.fill", color: NurturColors.accent) {
                        viewModel.startSleep()
                    }
                    LargeActionButton(title: Strings.Home.diaper, icon: "bubbles.and.sparkles", color: NurturColors.success) {
                        // Diaper has no timer — log from the Log tab for type selection
                    }
                    LargeActionButton(title: Strings.Home.askAI, icon: "bubble.left.and.bubble.right.fill", color: NurturColors.warning) {
                        assistQuery = nil
                        showAssist = true
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 8)
        }
        .background(NurturColors.background)
        .refreshable { await viewModel.refresh(baby: baby) }
        .onChange(of: viewModel.logVersion) { _, _ in
            Task { await viewModel.load(baby: baby) }
        }
        .errorAlert(error: $viewModel.error)
        .sheet(isPresented: $showAssist, onDismiss: { assistQuery = nil }) {
            AssistView(initialQuery: assistQuery)
        }
    }
}

private struct ActiveTimerWidget: View {
    let session: ActiveTimerSession
    let onStop: () -> Void
    @State private var elapsed: TimeInterval = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(NurturColors.accent.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseScale)
				Image(systemName: getTimerTextAndImage(session.type).imageName)
                    .foregroundStyle(NurturColors.accent)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
				Text(getTimerTextAndImage(session.type).text)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(formatElapsedTime(elapsed))
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(NurturColors.accent)
                    .contentTransition(.numericText())
            }

            Spacer()

            Button(Strings.Common.stop) { onStop() }
                .font(NurturTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(NurturColors.danger, in: Capsule())
        }
        .padding(16)
        .background(NurturColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .onAppear {
            pulseScale = 1.12
            elapsed = session.elapsed
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            elapsed = session.elapsed
        }
    }

    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

	private func getTimerTextAndImage(_ timerType: LogType) -> (text: String, imageName: String) {
		switch timerType {
		case .feed:
			return (Strings.Home.Timer.feedInProgress, "drop.fill")
		case .sleep:
			return (Strings.Home.Timer.sleepInProgress, "moon.fill")
		case .diaper:
			return ("Diaper in being changed", "bubbles.and.sparkles")
		case .mood:
			return ("Mood has changed","")
		}
	}
}
