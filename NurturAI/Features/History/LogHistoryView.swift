import SwiftUI
import SwiftData

struct LogHistoryView: View {
    @Environment(\.appContainer) private var container
    // Bug #4 fix: matches HomeView — newest baby first so re-onboarded
    // profiles aren't shadowed by a stale older record.
    @Query(sort: \Baby.createdAt, order: .reverse) private var babies: [Baby]
    @State private var viewModel: LogHistoryViewModel?

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    HistoryContentView(viewModel: vm, baby: baby)
                } else if babies.isEmpty {
                    ContentUnavailableView(Strings.Common.noBabyProfile, systemImage: "clock")
                } else {
                    ProgressView()
                        .tint(NurturColors.accent)
                }
            }
            .navigationTitle(Strings.History.navigationTitle)
            .nurturScreenBackground()
			.task {
				guard let baby = babies.first, let container else { return }
				let vm = LogHistoryViewModel(logRepository: container.logRepository, timerService: container.timerService)
				viewModel = vm
				await vm.load(baby: baby)
			}
			.onAppear {
				container?.analyticsService.logPageView("logHistoryView")
			}
    }
}

private struct HistoryContentView: View {
    @Bindable var viewModel: LogHistoryViewModel
    let baby: Baby
    @State private var editingLog: BabyLog?

    var body: some View {
        List {
            if viewModel.isLoading {
                ForEach(0..<4) { _ in
                    HistoryLogRowSkeleton()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                }
            } else if viewModel.sections.isEmpty {
                ContentUnavailableView(Strings.History.noLogsTitle, systemImage: "clock", description: Text(Strings.History.noLogsMessage))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.sections, id: \.date) { section in
                    Section(header: sectionHeader(for: section.date)) {
                        ForEach(section.logs) { log in
                            LogHistoryRow(log: log)
                                .contentShape(Rectangle())
                                .onTapGesture { editingLog = log }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                Task {
                                    await viewModel.delete(section.logs[idx], baby: baby)
                                }
                            }
                        }
                    }
                    .listSectionSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.load(baby: baby) }
        .errorAlert(error: $viewModel.error)
        .sheet(item: $editingLog) { log in
            LogEditSheet(log: log) { newStart, newEnd in
                await viewModel.update(log, baby: baby, newTimestamp: newStart, newEndTimestamp: newEnd)
            }
        }
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
        return HStack {
            Text(label)
                .font(NurturTypography.captionMedium)
                .fontWeight(.semibold)
                .foregroundStyle(NurturColors.textSecondary)
                .textCase(nil)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .nurturGlassPill()
            Spacer()
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 4, trailing: 20))
    }
}

private struct LogHistoryRow: View {
    let log: BabyLog

    var body: some View {
        HStack(spacing: 12) {
            GlassIconBadge(icon: logIcon, color: logColor, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(logTypeLabel)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(log.timestamp.shortDateTimeDisplay)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            Spacer(minLength: 12)

            Text(summaryText)
                .font(NurturTypography.captionMedium)
                .foregroundStyle(logColor)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(logColor.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nurturGlassRow(cornerRadius: 18)
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
            if let dur = log.durationSeconds { parts.append((dur / 60).hmDisplay) }
            return parts.joined(separator: " · ")
        case .sleep:
            if let dur = log.durationSeconds {
                return (dur / 60).hmDisplay
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

/// Shimmering placeholder matching `LogHistoryRow`'s footprint so the list
/// reserves its space while logs load instead of flashing a bare spinner.
private struct HistoryLogRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            NurturSkeletonBlock(width: 36, height: 36, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 6) {
                NurturSkeletonBlock(width: 76, height: 12, cornerRadius: 6)
                NurturSkeletonBlock(width: 112, height: 10, cornerRadius: 5)
            }
            Spacer()
            NurturSkeletonBlock(width: 58, height: 20, cornerRadius: 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nurturGlassRow(cornerRadius: 18)
    }
}

private struct LogEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let log: BabyLog
    let onSave: (Date, Date?) async -> Void

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isSaving = false

    private let hasEndTimestamp: Bool

    init(log: BabyLog, onSave: @escaping (Date, Date?) async -> Void) {
        self.log = log
        self.onSave = onSave
        _startDate = State(initialValue: log.timestamp)
        _endDate = State(initialValue: log.endTimestamp ?? log.timestamp)
        self.hasEndTimestamp = log.endTimestamp != nil
    }

    private var isValid: Bool {
        guard startDate <= .now else { return false }
        if hasEndTimestamp {
            return endDate > startDate && endDate <= .now
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 4) {
                    DatePicker(
                        Strings.History.editStartLabel,
                        selection: $startDate,
                        in: ...Date()
                    )
                    .font(NurturTypography.callout)
                    .padding(.vertical, 6)
                    if hasEndTimestamp {
                        Divider()
                            .overlay(NurturColors.textFaint.opacity(0.25))
                        DatePicker(
                            Strings.History.editEndLabel,
                            selection: $endDate,
                            in: startDate...Date()
                        )
                        .font(NurturTypography.callout)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .nurturGlassCard(cornerRadius: 24)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .nurturScreenBackground()
            .tint(NurturColors.accent)
            .navigationTitle(Strings.History.editTitle(log.type.rawValue.capitalized))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Common.save) {
                        isSaving = true
                        Task {
                            await onSave(startDate, hasEndTimestamp ? endDate : nil)
                            dismiss()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }
}
