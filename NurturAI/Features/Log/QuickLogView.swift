import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.appContainer) private var container
    // Bug #4 fix: matches HomeView — newest baby first so re-onboarded
    // profiles aren't shadowed by a stale older record.
    @Query(sort: \Baby.createdAt, order: .reverse) private var babies: [Baby]
    @State private var viewModel: QuickLogViewModel?
    @State private var selectedTab: LogType = .feed

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    QuickLogContentView(viewModel: vm, baby: baby, selectedTab: $selectedTab)
                } else if babies.isEmpty {
                    ContentUnavailableView(Strings.Common.noBabyProfile, systemImage: "plus.circle.fill")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.Log.navigationTitle)
			.task {
				guard let container, babies.first != nil else { return }
				if viewModel == nil {
					viewModel = QuickLogViewModel(timerService: container.timerService)
				}
			}
			.onAppear {
				container?.analyticsService.logPageView("QuickLogView")
			}
    }
}

private struct QuickLogContentView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby
    @Binding var selectedTab: LogType

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header — mirrors HomeView
                    HStack(spacing: 12) {
                        BabyAvatar(name: baby.name, size: 56)
                            .glassEffect(.regular, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(baby.name)
                                .font(NurturTypography.title3)
                                .foregroundStyle(NurturColors.textPrimary)
                            Text(Strings.Log.headerPrompt)
                                .font(NurturTypography.subheadline)
                                .foregroundStyle(NurturColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Animated liquid-glass type selector
                    LogTypeSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)

                    // Active control panel
                    Group {
                        switch selectedTab {
                        case .feed:   FeedTimerView(viewModel: viewModel, baby: baby)
                        case .sleep:  SleepTimerView(viewModel: viewModel, baby: baby)
                        case .diaper: DiaperLogView(viewModel: viewModel, baby: baby)
                        case .mood:   MoodLogView(viewModel: viewModel, baby: baby)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(selectedTab)
                }
                .padding(.top, 25)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
            }
            .background(
                LinearGradient(
                    colors: [.background, .accentColor.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )

            // Toast confirmation
            ToastOverlay(
                message: Strings.Log.savedConfirmation(viewModel.lastSavedLogType?.rawValue ?? ""),
                isShowing: viewModel.showSaveConfirmation
            )
        }
        .errorAlert(error: $viewModel.error)
    }
}

/// Liquid-glass segmented selector. Each segment carries its own brand color
/// and the selected pill slides between them via a matched-geometry animation.
private struct LogTypeSelector: View {
    @Binding var selectedTab: LogType
    @Namespace private var namespace

    private struct Tab { let type: LogType; let label: String; let icon: String; let color: Color }

    private let tabs: [Tab] = [
        Tab(type: .feed,   label: Strings.Log.tabFeed,   icon: "drop.fill",              color: NurturColors.info),
        Tab(type: .sleep,  label: Strings.Log.tabSleep,  icon: "moon.fill",              color: NurturColors.accent),
        Tab(type: .diaper, label: Strings.Log.tabDiaper, icon: "bubbles.and.sparkles",   color: NurturColors.success),
        Tab(type: .mood,   label: Strings.Log.tabMood,   icon: "face.smiling",           color: NurturColors.warning)
    ]

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 6) {
                ForEach(tabs, id: \.type) { tab in
                    let isSelected = selectedTab == tab.type
                    Button {
                        selectedTab = tab.type
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tab.label)
                                .font(NurturTypography.caption)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(isSelected ? .white : tab.color)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(tab.color)
                                    .shadow(color: tab.color.opacity(0.4), radius: 6, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "selectedTab", in: namespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selectedTab)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

private struct MoodLogView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text(Strings.Log.moodHeading(baby.name))
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MoodState.allCases, id: \.self) { mood in
                        let isSelected = viewModel.selectedMood == mood
                        Button {
                            viewModel.selectedMood = mood
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.emoji).font(.title)
                                Text(mood.label)
                                    .font(NurturTypography.caption)
                                    .fontWeight(isSelected ? .bold : .medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
                            .modifier(SelectionChipBackground(isSelected: isSelected, color: NurturColors.accent))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button(Strings.Common.logNow) {
                Task { await viewModel.logMood(baby: baby) }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.selectedMood)
        .sensoryFeedback(.selection, trigger: viewModel.selectedMood)
    }
}

/// A large, tappable circular timer control. Tapping starts or stops the timer;
/// while running it breathes, a progress ring sweeps to fill once every 60 s
/// (resetting each minute), and the center counter ticks up live. Colors follow
/// the active log type so it stays on-brand.
struct CircularTimerButton: View {
    let startTime: Date?
    let isRunning: Bool
    let color: Color
    let runningLabel: String
    let idleLabel: String
    let action: () -> Void

    @State private var pulse = false

    private let diameter: CGFloat = 220
    private let lineWidth: CGFloat = 10

    var body: some View {
        Button(action: action) {
            ZStack {
                // Breathing glow — only rendered while running, so the idle
                // state stays completely static and centered.
                if isRunning {
                    Circle()
                        .fill(color.opacity(0.16))
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(pulse ? 1.07 : 0.93)
                        .blur(radius: 8)
                        .transition(.opacity)
                        // Scoped to `pulse` so the repeating breath stays contained
                        // to this circle. An imperative withAnimation(.repeatForever)
                        // here leaked onto the shared timer-session transaction and
                        // animated Home's ActiveTimerWidget on every feed start.
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }

                // Frosted face — static material (not Liquid Glass) so it does
                // not play the sheen-sweep entrance animation on first appear.
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: diameter - 30, height: diameter - 30)
                    .background(.ultraThinMaterial, in: Circle())

                // Per-minute progress track
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)
                    .frame(width: diameter, height: diameter)

                // Live ring + counter while running, static otherwise
                if isRunning, let startTime {
                    TimelineView(.animation) { context in
                        let elapsed = max(0, context.date.timeIntervalSince(startTime))
                        let progress = elapsed.truncatingRemainder(dividingBy: 60) / 60
                        ZStack {
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: diameter, height: diameter)
                                // Mirror real elapsed time exactly — never let the
                                // arc inherit an implicit animation and sweep on appear.
                                .transaction { $0.animation = nil }
                            centerContent(elapsed: elapsed)
                        }
                    }
                } else {
                    centerContent(elapsed: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: isRunning)
    }

    private func centerContent(elapsed: TimeInterval) -> some View {
        VStack(spacing: 6) {
            Text(formatElapsed(elapsed))
                .font(.system(size: 46, weight: .light, design: .monospaced))
                .foregroundStyle(isRunning ? color : NurturColors.textSecondary)
                .contentTransition(.numericText())
            Text(isRunning ? runningLabel : idleLabel)
                .font(NurturTypography.caption)
                .foregroundStyle(NurturColors.textFaint)
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Shared selection-chip styling for the Log screen: a liquid-glass capsule when
/// idle, a filled brand-colored pill with a soft glow when selected.
struct SelectionChipBackground: ViewModifier {
    let isSelected: Bool
    var color: Color = NurturColors.accent
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        if isSelected {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(color)
                        .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
                )
        } else {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
