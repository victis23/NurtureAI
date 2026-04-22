import SwiftUI
import SwiftData

struct DiaperLogView: View {
    @Environment(DependencyContainer.self) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: DiaperLogViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    DiaperContentView(viewModel: vm, baby: baby)
                } else {
                    ContentUnavailableView("No baby profile", systemImage: "bubbles.and.sparkles")
                }
            }
            .navigationTitle("Diapers")
        }
        .task {
            guard let baby = babies.first else { return }
            let vm = DiaperLogViewModel(diaperRepo: container.diaperLogRepository)
            viewModel = vm
            await vm.loadLogs(for: baby)
        }
    }
}

private struct DiaperContentView: View {
    @Bindable var viewModel: DiaperLogViewModel
    let baby: Baby

    var body: some View {
        List {
            Section {
                HStack(spacing: 24) {
                    VStack {
                        Text("\(viewModel.wetCount24h)").font(.title).fontWeight(.bold).foregroundStyle(NurturColors.info)
                        Text("Wet (24h)").font(NurturTypography.caption).foregroundStyle(NurturColors.textSecondary)
                    }
                    Divider()
                    VStack {
                        Text("\(viewModel.dirtyCount24h)").font(.title).fontWeight(.bold).foregroundStyle(NurturColors.warning)
                        Text("Dirty (24h)").font(NurturTypography.caption).foregroundStyle(NurturColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            ForEach(viewModel.logs) { log in
                DiaperLogRow(log: log)
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
                ContentUnavailableView("No diapers logged", systemImage: "bubbles.and.sparkles")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.showingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            AddDiaperSheet(viewModel: viewModel, baby: baby)
        }
        .alert("Doctor's Attention May Be Needed", isPresented: $viewModel.showingColorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.colorAlertMessage)
        }
    }
}

private struct DiaperLogRow: View {
    let log: DiaperLog

    var body: some View {
        HStack {
            Text(log.type.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(log.type.rawValue).font(.subheadline).fontWeight(.medium)
                Text(log.timestamp.relativeDisplay).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let color = log.color {
                Text(color.rawValue).font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(color.requiresDoctorAttention ? NurturColors.danger.opacity(0.15) : NurturColors.textFaint.opacity(0.15), in: Capsule())
                    .foregroundStyle(color.requiresDoctorAttention ? NurturColors.danger : NurturColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddDiaperSheet: View {
    @Bindable var viewModel: DiaperLogViewModel
    let baby: Baby

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Diaper type", selection: $viewModel.selectedType) {
                        ForEach(DiaperLog.DiaperType.allCases, id: \.self) {
                            Text($0.emoji + " " + $0.rawValue).tag($0)
                        }
                    }.pickerStyle(.segmented)
                }
                Section("Time") {
                    DatePicker("Time", selection: $viewModel.timestamp, displayedComponents: [.date, .hourAndMinute])
                }
                if viewModel.selectedType == .dirty || viewModel.selectedType == .both {
                    Section("Stool Details (optional)") {
                        Picker("Color", selection: $viewModel.selectedColor) {
                            Text("Not set").tag(DiaperLog.StoolColor?.none)
                            ForEach(DiaperLog.StoolColor.allCases, id: \.self) {
                                Text($0.rawValue).tag(DiaperLog.StoolColor?.some($0))
                            }
                        }.pickerStyle(.menu)

                        Picker("Consistency", selection: $viewModel.selectedConsistency) {
                            Text("Not set").tag(DiaperLog.StoolConsistency?.none)
                            ForEach(DiaperLog.StoolConsistency.allCases, id: \.self) {
                                Text($0.rawValue).tag(DiaperLog.StoolConsistency?.some($0))
                            }
                        }.pickerStyle(.menu)
                    }
                }
                Section {
                    Toggle("Diaper rash", isOn: $viewModel.hasRash)
                }
                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Log Diaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.resetForm() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.saveLog(for: baby) }
                    }
                }
            }
        }
    }
}
