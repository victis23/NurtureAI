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

/// Wraps a timer's content with a soft brand-colored halo that gently breathes
/// while the timer is running, so the screen feels alive instead of static.
struct TimerHalo<Content: View>: View {
    let isRunning: Bool
    var color: Color = NurturColors.accent
    @ViewBuilder var content: Content

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 190, height: 190)
                .scaleEffect(pulse ? 1.06 : 0.9)
                .opacity(isRunning ? 1 : 0)
                .blur(radius: 4)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                .animation(.easeOut(duration: 0.4), value: isRunning)
            content
        }
        .frame(maxWidth: .infinity)
        .onAppear { pulse = true }
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
