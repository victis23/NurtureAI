import SwiftUI
import SwiftData

struct LogHistoryView: View {
    @Environment(\.appContainer) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: LogHistoryViewModel?

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    HistoryContentView(viewModel: vm, baby: baby)
                } else if babies.isEmpty {
                    ContentUnavailableView(Strings.Common.noBabyProfile, systemImage: "clock")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.History.navigationTitle)
			.task {
				guard let baby = babies.first, let container else { return }
				let vm = LogHistoryViewModel(logRepository: container.logRepository)
				viewModel = vm
				await vm.load(baby: baby)
			}
    }
}

private struct HistoryContentView: View {
    @Bindable var viewModel: LogHistoryViewModel
    let baby: Baby

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if viewModel.sections.isEmpty {
                ContentUnavailableView(Strings.History.noLogsTitle, systemImage: "clock", description: Text(Strings.History.noLogsMessage))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.sections, id: \.date) { section in
                    Section(header: sectionHeader(for: section.date)) {
                        ForEach(section.logs) { log in
                            LogHistoryRow(log: log)
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                Task {
                                    await viewModel.delete(section.logs[idx], baby: baby)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(NurturColors.background)
        .refreshable { await viewModel.load(baby: baby) }
        .errorAlert(error: $viewModel.error)
    }

    private func sectionHeader(for date: Date) -> some View {
        let calendar = Calendar.current
        let label: String
        if calendar.isDateInToday(date) {
            label = Strings.History.today
        } else if calendar.isDateInYesterday(date) {
            label = Strings.History.yesterday
        } else {
            label = date.formatted(date: .abbreviated, time: .omitted)
        }
        return Text(label)
            .font(NurturTypography.caption)
            .foregroundStyle(NurturColors.textSecondary)
            .textCase(nil)
    }
}

private struct LogHistoryRow: View {
    let log: BabyLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: logIcon)
                .foregroundStyle(logColor)
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(logTypeLabel)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(log.timestamp.shortDateTimeDisplay)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            Spacer()

            Text(summaryText)
                .font(NurturTypography.caption)
                .foregroundStyle(NurturColors.textFaint)
        }
        .padding(.vertical, 4)
    }

    private var logIcon: String {
        switch log.type {
        case .feed:   return "drop.fill"
        case .sleep:  return "moon.fill"
        case .diaper: return "bubbles.and.sparkles"
        case .mood:   return "face.smiling"
        }
    }

    private var logColor: Color {
        switch log.type {
        case .feed:   return NurturColors.info
        case .sleep:  return NurturColors.accent
        case .diaper: return NurturColors.success
        case .mood:   return NurturColors.warning
        }
    }

    private var logTypeLabel: String {
        log.type.rawValue.capitalized
    }

    private var summaryText: String {
        switch log.metadata {
        case .feed(let side, let ml):
            var parts = [side.rawValue.capitalized]
            if let ml { parts.append("\(ml) ml") }
            if let dur = log.durationSeconds { parts.append("\(dur / 60) min") }
            return parts.joined(separator: " · ")
        case .sleep:
            if let dur = log.durationSeconds {
                return "\(dur / 60) min"
            }
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
