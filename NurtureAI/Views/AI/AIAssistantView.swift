import SwiftUI
import SwiftData

struct AIAssistantView: View {
    @Environment(DependencyContainer.self) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: AIAssistantViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    AIContentView(viewModel: vm, baby: baby)
                } else {
                    ContentUnavailableView("No baby profile", systemImage: "sparkles")
                }
            }
            .navigationTitle("Ask AI")
            .toolbar {
                if let vm = viewModel, let baby = babies.first {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await vm.clearConversation(for: baby) }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .task {
            guard let baby = babies.first else { return }
            let vm = AIAssistantViewModel(
                aiService: container.aiService,
                contextBuilder: container.contextBuilder,
                safetyFilter: container.safetyFilter,
                responseParser: container.responseParser,
                conversationRepo: container.conversationRepository
            )
            viewModel = vm
            await vm.loadOrCreateConversation(for: baby)
        }
    }
}

private struct AIContentView: View {
    @Bindable var viewModel: AIAssistantViewModel
    let baby: Baby
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.purple)
                                Text("Ask anything about \(baby.name)")
                                    .font(.headline)
                                Text("Sleep schedules, feeding tips, development milestones — I'll answer based on \(baby.name)'s actual logged data.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        }

                        ForEach(viewModel.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }

                        if viewModel.isStreaming && !viewModel.streamingResponse.isEmpty {
                            StreamingBubble(text: viewModel.streamingResponse)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: viewModel.streamingResponse) {
                    withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Ask about \(baby.name)...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await viewModel.send(for: baby) }
                    }

                Button {
                    Task { await viewModel.send(for: baby) }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(viewModel.inputText.isEmpty ? .secondary : .purple)
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isStreaming)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct MessageBubble: View {
    let message: AIAssistantViewModel.DisplayMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(bubbleColor, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(isUser ? .white : .primary)

                if message.urgencyLevel == .urgent {
                    Label("This may be urgent", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.red)
                }
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }

    var bubbleColor: Color {
        if isUser { return .purple }
        switch message.urgencyLevel {
        case .urgent: return Color.red.opacity(0.1)
        case .advisory: return Color.orange.opacity(0.1)
        case .normal: return Color(.secondarySystemBackground)
        }
    }
}

private struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack {
            Text(text + " ●")
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                .animation(.easeInOut(duration: 0.3), value: text)
            Spacer(minLength: 48)
        }
    }
}
