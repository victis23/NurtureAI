import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    // Bug #4 fix: default sort order is .forward, which means after a
    // delete-and-recreate cycle the *oldest* surviving baby gets selected.
    // Reverse the order so `babies.first` is always the most-recent profile.
    @Query(sort: \Baby.createdAt, order: .reverse) private var babies: [Baby]
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
					timerService: container.timerService,
					notificationService: container.notificationService
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
	@State private var babyState: CharacterAnimation = .relaxing
	@State private var buttonTap: Bool? = false

    var body: some View {
		ZStack {
			VStack(){
				HStack(){
					CharacterView(state: babyState)
						.frame(width: 350, height: 350)
						.opacity(0.7)
						.padding(.leading, -40)
						.padding(.top, 350)
					Spacer()
				}
			}
			.padding(.bottom, 20)
			
			ScrollView {
					VStack(spacing: 20) {
						// Header
						HStack(spacing: 12) {
							BabyAvatar(name: baby.name, size: 56)
								.glassEffect(.regular, in: Circle())
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
						// Suppressed during an active sleep session — the awake
						// window the saved patterns report is from before sleep
						// started, so the "approaching the limit" warning would
						// be stale (and contradicting what the parent is doing).
						if let patterns = viewModel.patterns,
						   viewModel.activeTimerSession?.type != .sleep,
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
						
						// Status cards — wrapped in a TimelineView so "Xm ago" labels
						// tick every 60 s without a full pattern reload. SwiftUI
						// automatically suspends the timeline when the view is off
						// screen, so this is battery-friendly.
						if let patterns = viewModel.patterns {
							TimelineView(.periodic(from: .now, by: 60)) { context in
								let nextState: CharacterAnimation = {
									switch viewModel.activeTimerSession?.type {
									case .sleep: return .sleeping
									case .feed:  return .feeding
									default:     break
									}
									let urgent = viewModel.isFeedUrgent(at: context.date)
									|| viewModel.isAwakeUrgent(at: context.date)
									|| viewModel.isDiaperUrgent(baby: baby, at: context.date)
									return urgent ? .crying : .relaxing
								}()

								GlassEffectContainer {
									LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
										NurturStatusCard(
											title: Strings.Home.Status.lastFed,
											value: viewModel.lastFedDisplay(at: context.date) ?? Strings.Home.notLogged,
											subtitle: patterns.feedingsToday > 0 ? "\(patterns.feedingsToday) \(Strings.Home.feedingsToday)" : nil,
											icon: "drop.fill",
											iconColor: NurturColors.info,
											isUrgent: viewModel.isFeedUrgent(at: context.date)
										)
										
										NurturStatusCard(
											title: Strings.Home.Status.awake,
											value: viewModel.awakeDisplay(at: context.date) ?? Strings.Home.notLogged,
											subtitle: Strings.Home.Status.maxAwake("\(patterns.ageAppropriateMaxAwakeMinutes)"),
											icon: "sun.max.fill",
											iconColor: NurturColors.warning,
											isUrgent: viewModel.isAwakeUrgent(at: context.date)
										)
										
										NurturStatusCard(
											title: Strings.Home.Status.sleepToday,
											value: viewModel.sleepTodayDisplay(at: context.date) ?? Strings.Home.notLogged,
											icon: "moon.fill",
											iconColor: NurturColors.accent
										)
										
										NurturStatusCard(
											title: Strings.Home.Status.lastDiaper,
											value: viewModel.lastDiaperDisplay(at: context.date) ?? Strings.Home.notLogged,
											icon: "bubbles.and.sparkles",
											iconColor: NurturColors.success,
											isUrgent: viewModel.isDiaperUrgent(baby: baby, at: context.date)
										)
									}
									.onChange(of: nextState, initial: true) { _, new in
										babyState = new
									}
								}
							}
							.padding(.horizontal)
							.transition(.opacity)
						}
						
						// Quick-action row
						HStack(spacing: 12) {
							LargeActionButton(title: Strings.Home.feed, icon: "drop.fill", color: NurturColors.info) {
								buttonTap?.toggle()
								Task {
									if let session = viewModel.activeTimerSession {
										await viewModel.stopActiveTimer(baby: baby)
										if session.type != .feed {
											viewModel.startFeed()
										}
									} else {
										viewModel.startFeed()
									}
								}
							}.sensoryFeedback(.impact, trigger: buttonTap)

							LargeActionButton(title: Strings.Home.sleep, icon: "moon.fill", color: NurturColors.accent) {
								buttonTap?.toggle()
								Task {
									if let session = viewModel.activeTimerSession {
										await viewModel.stopActiveTimer(baby: baby)
										if session.type != .sleep {
											viewModel.startSleep()
										}
									} else {
										viewModel.startSleep()
									}
								}
							}.sensoryFeedback(.impact, trigger: buttonTap)
	
							LargeActionButton(title: Strings.Home.diaper, icon: "bubbles.and.sparkles", color: NurturColors.success) {
								viewModel.logDiaperFor(baby: baby)
								buttonTap?.toggle()
							}.sensoryFeedback(.impact, trigger: buttonTap)

							LargeActionButton(title: Strings.Home.askAI, icon: "bubble.left.and.bubble.right.fill", color: NurturColors.warning) {
								assistQuery = nil
								showAssist = true
								buttonTap?.toggle()
							}.sensoryFeedback(.impact, trigger: buttonTap)
						}
						.padding(.horizontal)
					}
					.padding(.top, 25)
					.animation(.easeOut(duration: 0.4), value: viewModel.patterns == nil)
			}
			.background(LinearGradient(
				colors: [.background, .accentColor.opacity(0.1)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing))
			.padding(.top)
			.refreshable { await viewModel.refresh(baby: baby) }
			.onChange(of: viewModel.logVersion) { _, _ in
				Task { await viewModel.handleLogSaved(baby: baby) }
			}
			.errorAlert(error: $viewModel.error)
			.sheet(isPresented: $showAssist, onDismiss: { assistQuery = nil }) {
				AssistView(initialQuery: assistQuery)
			}
		}
    }
}

private struct ActiveTimerWidget: View {
    let session: ActiveTimerSession
    let onStop: () -> Void
    @State private var elapsed: TimeInterval = 0
    @State private var pulseScale: CGFloat = 1.0
	let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	@State private var buttonTap = false

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

			Button(Strings.Common.stop) {
				buttonTap.toggle()
				onStop()
			}
			.font(NurturTypography.subheadline)
			.fontWeight(.semibold)
			.foregroundStyle(.white)
			.padding(.horizontal, 16)
			.padding(.vertical, 8)
			.background(NurturColors.danger, in: Capsule())
			.sensoryFeedback(.impact, trigger: buttonTap)
        }
        .padding(16)
        .background(NurturColors.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .onAppear {
            pulseScale = 1.12
            elapsed = session.elapsed
        }
        .onReceive(timerPublisher) { _ in
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
			return (Strings.Home.Timer.diaperInProgress, "bubbles.and.sparkles")
		case .mood:
			return (Strings.Home.Timer.moodLogged, "face.smiling")
		}
	}
}
