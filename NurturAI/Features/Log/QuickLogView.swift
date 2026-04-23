import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.appContainer) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
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
					viewModel = QuickLogViewModel(
						logRepository: container.logRepository,
						contextBuilder: container.contextBuilder,
						syncService: container.syncService
					)
				}
			}
    }
}

private struct QuickLogContentView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby
    @Binding var selectedTab: LogType

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 4-tab segmented control
                Picker("Log type", selection: $selectedTab) {
                    Text(Strings.Log.tabFeed).tag(LogType.feed)
                    Text(Strings.Log.tabSleep).tag(LogType.sleep)
                    Text(Strings.Log.tabDiaper).tag(LogType.diaper)
                    Text(Strings.Log.tabMood).tag(LogType.mood)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .feed:
                            FeedTimerView(viewModel: viewModel, baby: baby)
                                .padding()
                        case .sleep:
                            SleepTimerView(viewModel: viewModel, baby: baby)
                                .padding()
                        case .diaper:
                            DiaperLogView(viewModel: viewModel, baby: baby)
                                .padding()
                        case .mood:
                            MoodLogView(viewModel: viewModel, baby: baby)
                                .padding()
                        }
                    }
                }
            }
            .background(NurturColors.background)

            // Toast confirmation
            ToastOverlay(
                message: Strings.Log.savedConfirmation(viewModel.lastSavedLogType?.rawValue ?? ""),
                isShowing: viewModel.showSaveConfirmation
            )
        }
        .errorAlert(error: $viewModel.error)
    }
}

private struct MoodLogView: View {
    @Bindable var viewModel: QuickLogViewModel
    let baby: Baby

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.Log.moodHeading(baby.name))
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(MoodState.allCases, id: \.self) { mood in
                        Button {
                            viewModel.selectedMood = mood
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.emoji).font(.title2)
                                Text(mood.label)
                                    .font(NurturTypography.caption)
                                    .fontWeight(viewModel.selectedMood == mood ? .semibold : .regular)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                viewModel.selectedMood == mood ? NurturColors.accentSoft : NurturColors.surfaceWarm,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(
                                viewModel.selectedMood == mood ? NurturColors.accent : NurturColors.textPrimary
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.selectedMood == mood ? NurturColors.accent : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
            }

            Button(Strings.Common.logNow) {
                Task { await viewModel.logMood(baby: baby) }
            }
            .primaryButton()
        }
    }
}
