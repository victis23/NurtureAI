import SwiftUI
import SwiftData
import Combine
import AppTrackingTransparency

struct HomeView: View {
    @Environment(AppState.self) private var appState
	@Environment(\.scenePhase) var scenePhase
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
				viewModel = HomeViewModel(
					logRepository: container.logRepository,
					patternService: container.patternService,
					timerService: container.timerService,
					notificationService: container.notificationService
				)

				await viewModel?.load(baby: baby)
			}
			.onChange(of: scenePhase, { _, newPhase in
				if newPhase == .active && !appState.permissionsGranted {
					Task {
						await ATTrackingManager.requestTrackingAuthorization()
					}
				}
			})
			.onAppear {
				container?.analyticsService.logPageView("homeView")
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
	@State private var scoreExpanded: Bool = false

	private var parentingScore: ParentingScore? {
		viewModel.parentingScore(baby: baby, at: Date())
	}

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
						// Header drawer
						VStack(spacing: 0) {
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
								if let score = parentingScore {
									HStack(spacing: 6) {
										ScoreGauge(score: score.value, size: 30, lineWidth: 3, showSubtitle: false)
										Image(systemName: "chevron.down")
											.font(.caption2)
											.fontWeight(.bold)
											.foregroundStyle(NurturColors.textFaint)
											.rotationEffect(.degrees(scoreExpanded ? 180 : 0))
									}
									.padding(.horizontal, 10)
									.padding(.vertical, 5)
									.background(score.pillTone.soft, in: Capsule())
								}
							}
							.padding(16)
							.contentShape(Rectangle())
							.onTapGesture {
								withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
									scoreExpanded.toggle()
								}
							}
							if scoreExpanded, let score = parentingScore {
								VStack(spacing: 0) {
									Divider().opacity(0.3)
									ParentingScoreCard(score: score, showBackground: false)
								}
								.transition(.move(edge: .top).combined(with: .opacity))
							}
						}
						// Clip first so the expanding score drawer stays inside the
						// rounded shape, then wrap in the glass card (rim + shadow)
						// so neither gets clipped away.
						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
						.nurturGlassCard(cornerRadius: 22)
						.padding(.horizontal)
						
						// Active timer widget
						if let session = viewModel.activeTimerSession {
							ActiveTimerWidget(session: session) {
								Task { await viewModel.stopActiveTimer(baby: baby) }
							}
							.padding(.horizontal)
							// Belt-and-suspenders: don't let an animation transaction
							// from elsewhere (e.g. the Log screen's timer pulse) drive
							// this widget's insertion — that produced the perpetual bounce.
							.transaction { $0.animation = nil }
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
						if viewModel.patterns != nil || viewModel.isLoading {
							VStack(spacing: 12) {
								NurturSectionHeader(title: Strings.Home.atAGlance)
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
								} else {
									GlassEffectContainer {
										LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
											ForEach(0..<4, id: \.self) { _ in
												NurturStatusCardSkeleton()
											}
										}
									}
								}
							}
							.padding(.horizontal)
						}

						// Quick log
						VStack(spacing: 12) {
							NurturSectionHeader(title: Strings.Home.quickLog)
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
						}
						.padding(.horizontal)

						// Today's timeline
						TodayTimelineSection(logs: viewModel.todaysLogs, isLoading: viewModel.isLoading)
							.padding(.horizontal)
					}
					.padding(.top, 25)
			}
			.refreshable { await viewModel.refresh(baby: baby) }
			.onChange(of: viewModel.logVersion) { _, _ in
				Task { await viewModel.handleLogSaved(baby: baby) }
			}
			.errorAlert(error: $viewModel.error)
			.sheet(isPresented: $showAssist, onDismiss: { assistQuery = nil }) {
				AssistView(initialQuery: assistQuery)
			}
		}
		.nurturScreenBackground()
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
			.buttonStyle(.glassProminent)
			.tint(NurturColors.danger)
			.sensoryFeedback(.impact, trigger: buttonTap)
        }
        .padding(16)
        .nurturGlassCardTinted(NurturColors.accent, cornerRadius: 22)
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

// MARK: - Today's timeline

private struct TodayTimelineSection: View {
	let logs: [BabyLog]
	let isLoading: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			NurturSectionHeader(title: Strings.Home.timeline)

			if logs.isEmpty && isLoading {
				VStack(spacing: 12) {
					ForEach(0..<3, id: \.self) { _ in
						NurturTimelineRowSkeleton()
					}
				}
			} else if logs.isEmpty {
				EmptyTimelineCard()
			} else {
				ZStack(alignment: .topLeading) {
					Rectangle()
						.fill(
							LinearGradient(
								colors: [NurturColors.accent.opacity(0.35), NurturColors.accent.opacity(0.08)],
								startPoint: .top,
								endPoint: .bottom
							)
						)
						.frame(width: 2)
						.padding(.leading, 16)
						.padding(.vertical, 17)

					VStack(spacing: 12) {
						ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
							TimelineEventRow(log: log, isNow: index == 0)
						}
					}
				}
			}
		}
	}
}

private struct TimelineEventRow: View {
	let log: BabyLog
	let isNow: Bool

	var body: some View {
		HStack(alignment: .top, spacing: 12) {
			TimelineNode(log: log, isNow: isNow)

			VStack(alignment: .leading, spacing: 2) {
				HStack(alignment: .firstTextBaseline) {
					Text(title)
						.font(NurturTypography.subheadline)
						.fontWeight(.bold)
						.foregroundStyle(NurturColors.textPrimary)
					Spacer()
					Text(log.timestamp.timeDisplay)
						.font(NurturTypography.caption)
						.fontWeight(.bold)
						.foregroundStyle(NurturColors.textFaint)
				}
				Text(summary)
					.font(NurturTypography.caption)
					.foregroundStyle(NurturColors.textSecondary)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 11)
			.frame(maxWidth: .infinity, alignment: .leading)
			.nurturGlassRow(cornerRadius: 18)
		}
	}

	private var title: String {
		switch log.type {
		case .feed:   return Strings.Home.TimelineEvent.feed
		case .sleep:  return Strings.Home.TimelineEvent.sleep
		case .diaper: return Strings.Home.TimelineEvent.diaperChange
		case .mood:   return Strings.Home.TimelineEvent.mood
		}
	}

	private var summary: String {
		switch log.metadata {
		case .feed(let side, let ml):
			var parts = [side.rawValue.capitalized]
			if let ml { parts.append("\(ml) ml") }
			if let dur = log.durationSeconds { parts.append((dur / 60).hmDisplay) }
			return parts.joined(separator: " · ")
		case .sleep:
			if let dur = log.durationSeconds { return (dur / 60).hmDisplay }
			return "—"
		case .diaper(let type):
			return type.rawValue.capitalized
		case .mood(let state, _):
			return "\(state.emoji) \(state.label)"
		case .none:
			return "—"
		}
	}
}

private struct TimelineNode: View {
	let log: BabyLog
	let isNow: Bool
	@State private var pulse = false

	private var color: Color {
		switch log.type {
		case .feed:   return NurturColors.info
		case .sleep:  return NurturColors.accent
		case .diaper: return NurturColors.success
		case .mood:   return NurturColors.warning
		}
	}

	private var icon: String {
		switch log.type {
		case .feed:   return "drop.fill"
		case .sleep:  return "moon.fill"
		case .diaper: return "bubbles.and.sparkles"
		case .mood:   return "face.smiling"
		}
	}

	var body: some View {
		ZStack {
			if isNow {
				Circle()
					.stroke(NurturColors.accent.opacity(0.4), lineWidth: 2)
					.scaleEffect(pulse ? 1.6 : 1.0)
					.opacity(pulse ? 0 : 1)
					.animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: pulse)
			}
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(isNow ? NurturColors.accent : color.opacity(0.18))
			Image(systemName: icon)
				.font(.system(size: 14))
				.foregroundStyle(isNow ? Color.white : color)
		}
		.frame(width: 34, height: 34)
		.onAppear { if isNow { pulse = true } }
	}
}

private struct EmptyTimelineCard: View {
	var body: some View {
		VStack(spacing: 8) {
			Text("🌤️")
				.font(.system(size: 30))
			Text(Strings.Home.EmptyTimeline.title)
				.font(NurturTypography.headline)
				.foregroundStyle(NurturColors.textPrimary)
			Text(Strings.Home.EmptyTimeline.message)
				.font(NurturTypography.caption)
				.foregroundStyle(NurturColors.textSecondary)
				.multilineTextAlignment(.center)
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 28)
		.padding(.horizontal, 24)
		.nurturGlassCard(cornerRadius: 26)
		.overlay(
			// Keep the dashed "nothing here yet" charm as an inset stitch
			// on top of the glass card.
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
				.foregroundStyle(NurturColors.accent.opacity(0.35))
				.padding(6)
		)
	}
}
