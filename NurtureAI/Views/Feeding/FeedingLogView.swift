import SwiftUI
import SwiftData

struct FeedingLogView: View {
    @Environment(DependencyContainer.self) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: FeedingLogViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    FeedingContentView(viewModel: vm, baby: baby)
                } else {
                    ContentUnavailableView("No baby profile", systemImage: "drop.fill")
                }
            }
            .navigationTitle("Feeding")
        }
        .task {
            guard let baby = babies.first else { return }
            let vm = FeedingLogViewModel(feedingRepo: container.feedingLogRepository)
            viewModel = vm
            await vm.loadLogs(for: baby)
        }
    }
}

private struct FeedingContentView: View {
    @Bindable var viewModel: FeedingLogViewModel
    let baby: Baby

    var body: some View {
        List {
            ForEach(viewModel.logs) { log in
                FeedingLogRow(log: log)
            }
            .onDelete { indexSet in
                Task {
                    for idx in indexSet {
                        await viewModel.deleteLog(viewModel.logs[idx], for: baby)
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading { ProgressView() }
            if viewModel.logs.isEmpty && !viewModel.isLoading {
                ContentUnavailableView("No feedings logged", systemImage: "drop", description: Text("Tap + or Start Timer to log a feeding."))
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddFeedingSheet(viewModel: viewModel, baby: baby)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.isTimerRunning {
                    Button("Stop (\(viewModel.elapsedDisplay))") {
                        viewModel.stopTimer()
                        Task { await viewModel.saveLog(for: baby) }
                    }
                    .foregroundStyle(NurturColors.danger)
                } else {
                    Button("Start Timer") { viewModel.startTimer() }
                }
            }
        }
    }
}

private struct FeedingLogRow: View {
    let log: FeedingLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.type.rawValue).font(.subheadline).fontWeight(.medium)
                Text(log.startTime.relativeDisplay).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(log.durationDisplay).font(.subheadline)
                if let ml = log.amountMl {
                    Text("\(Int(ml)) ml").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddFeedingSheet: View {
    @Bindable var viewModel: FeedingLogViewModel
    let baby: Baby

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed Type") {
                    Picker("Type", selection: $viewModel.selectedType) {
                        ForEach(FeedingLog.FeedType.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Amount (optional)") {
                    HStack {
                        TextField("Amount", text: $viewModel.amountText)
                            .keyboardType(.decimalPad)
                        Text("ml").foregroundStyle(.secondary)
                    }
                }
                Section("Time") {
                    DatePicker("Start", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Log Feeding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.resetForm() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.saveLog(for: baby) }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
