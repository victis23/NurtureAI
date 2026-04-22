import SwiftUI
import SwiftData

struct SleepLogView: View {
    @Environment(DependencyContainer.self) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: SleepLogViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    SleepContentView(viewModel: vm, baby: baby)
                } else {
                    ContentUnavailableView("No baby profile", systemImage: "moon.fill")
                }
            }
            .navigationTitle("Sleep")
        }
        .task {
            guard let baby = babies.first else { return }
            let vm = SleepLogViewModel(sleepRepo: container.sleepLogRepository)
            viewModel = vm
            await vm.loadLogs(for: baby)
        }
    }
}

private struct SleepContentView: View {
    @Bindable var viewModel: SleepLogViewModel
    let baby: Baby

    var body: some View {
        VStack(spacing: 0) {
            // Sleep timer card
            VStack(spacing: 12) {
                if viewModel.isSleeping {
                    Text("Sleeping")
                        .font(.title2).fontWeight(.semibold)
                    Text(viewModel.elapsedDisplay)
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundStyle(.indigo)
                    Button("End Sleep") {
                        Task { await viewModel.endSleep(for: baby) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                } else {
                    Button("Start Sleep") {
                        Task { await viewModel.startSleep(for: baby) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Button("Log manually") { viewModel.showingAddSheet = true }
                        .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)

            List {
                ForEach(viewModel.logs) { log in
                    SleepLogRow(log: log)
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
                if viewModel.logs.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("No sleep logged", systemImage: "moon")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddSleepSheet(viewModel: viewModel, baby: baby)
        }
    }
}

private struct SleepLogRow: View {
    let log: SleepLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.location.rawValue).font(.subheadline).fontWeight(.medium)
                Text(log.startTime.relativeDisplay).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(log.durationDisplay).font(.subheadline)
                if let quality = log.quality {
                    Text(quality.emoji + " " + quality.rawValue).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddSleepSheet: View {
    @Bindable var viewModel: SleepLogViewModel
    let baby: Baby

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Location", selection: $viewModel.selectedLocation) {
                        ForEach(SleepLog.SleepLocation.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }.pickerStyle(.menu)
                }
                Section("Times") {
                    DatePicker("Start", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
                    Toggle("Add end time", isOn: Binding(
                        get: { viewModel.endTime != nil },
                        set: { viewModel.endTime = $0 ? Date() : nil }
                    ))
                    if viewModel.endTime != nil {
                        DatePicker("End", selection: Binding(
                            get: { viewModel.endTime ?? Date() },
                            set: { viewModel.endTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section("Quality (optional)") {
                    Picker("Quality", selection: $viewModel.selectedQuality) {
                        Text("Not set").tag(SleepLog.SleepQuality?.none)
                        ForEach(SleepLog.SleepQuality.allCases, id: \.self) {
                            Text($0.emoji + " " + $0.rawValue).tag(SleepLog.SleepQuality?.some($0))
                        }
                    }.pickerStyle(.menu)
                }
                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.resetForm() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.saveManualLog(for: baby) }
                    }
                }
            }
        }
    }
}
