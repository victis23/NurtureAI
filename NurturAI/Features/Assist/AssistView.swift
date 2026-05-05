import SwiftUI
import SwiftData

struct AssistView: View {
    var initialQuery: String? = nil

    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    // Bug #4 fix: matches HomeView — newest baby first so re-onboarded
    // profiles aren't shadowed by a stale older record.
    @Query(sort: \Baby.createdAt, order: .reverse) private var babies: [Baby]
    @State private var viewModel: AssistViewModel?

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    AssistContentView(viewModel: vm, baby: baby, container: container)
                } else if babies.isEmpty {
                    ContentUnavailableView(Strings.Common.noBabyProfile, systemImage: "bubble.left.and.bubble.right")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Strings.Assist.navigationTitle)
			.task {
				guard let _ = babies.first, let container else { return }
				let vm = AssistViewModel(
					orchestrator: container.orchestrator,
					contextBuilder: container.contextBuilder,
					safetyFilter: container.safetyFilter,
					insightRepository: container.insightRepository,
					appState: appState
				)
				if let q = initialQuery { vm.query = q }
				viewModel = vm
			}
			.sheet(isPresented: Binding(
				get: { viewModel?.showPaywall ?? false },
				set: { viewModel?.showPaywall = $0 }
			)) {
				PaywallView()
			}
    }
}

private struct AssistContentView: View {
    @Bindable var viewModel: AssistViewModel
    let baby: Baby
    let container: AppContainer?
    @FocusState private var isInputFocused: Bool
    @Namespace private var glassNamespace

    private var sendDisabled: Bool {
        viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        // Defer one runloop so the layout containing the just-added turn /
        // newly-arrived response is in the hierarchy before we ask SwiftUI
        // to scroll to it. Without this, the scroll target is sometimes the
        // pre-update layout and the new content stays clipped below the fold.
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                proxy.scrollTo("assist.bottom", anchor: .bottom)
            }
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    NurturColors.background, NurturColors.accentSoft.opacity(0.4), NurturColors.background,
                    NurturColors.accentSoft.opacity(0.3), NurturColors.background, NurturColors.surfaceWarm,
                    NurturColors.background, NurturColors.surfaceWarm.opacity(0.5), NurturColors.accentSoft.opacity(0.2)
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Baby chip bar
                GlassEffectContainer(spacing: 12) {
                    HStack {
                        Text("\(baby.name) · \(baby.displayAge)")
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(in: Capsule())

                        Spacer()

                        if !viewModel.appState.isSubscribed {
                            Text("\(max(0, 3 - viewModel.dailyQueryCount)) \(Strings.Assist.freeLeft)")
                                .font(NurturTypography.caption2)
                                .foregroundStyle(NurturColors.textFaint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .glassEffect(in: Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Emergency banner
                            if viewModel.emergencyMode {
                                EscalationBannerView(isEmergency: true, callDoctorItems: [])
                                    .padding(.horizontal)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            if !viewModel.emergencyMode {
                                // Quick picks — only at the start of a fresh conversation.
                                if viewModel.turns.isEmpty && !viewModel.isStreaming {
                                    QuickPicksView { pick in
                                        viewModel.query = pick
                                        isInputFocused = true
                                    }
                                    .padding(.top, 8)
                                    .transition(.blurReplace)
                                }

                                // Conversation turns
                                ForEach(Array(viewModel.turns.enumerated()), id: \.element.id) { index, turn in
                                    let isLatest = index == viewModel.turns.count - 1
                                    AssistTurnView(
                                        turn: turn,
                                        isLatest: isLatest,
                                        isStreaming: viewModel.isStreaming && isLatest,
                                        showDoctorBanner: viewModel.showEscalationBanner && !viewModel.emergencyMode && isLatest && turn.response == nil,
                                        onFeedback: { wasHelpful in
                                            viewModel.recordFeedback(turnID: turn.id, wasHelpful: wasHelpful)
                                        }
                                    )
                                    .id(turn.id)
                                    .transition(.opacity.combined(with: .offset(y: 12)))
                                }

                                // Ask another / new conversation
                                if !viewModel.turns.isEmpty,
                                   !viewModel.isStreaming,
                                   viewModel.turns.last?.response != nil {
                                    Button {
                                        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                                            viewModel.clearQuery()
                                        }
                                    } label: {
                                        Label(Strings.Assist.askAnother, systemImage: "arrow.counterclockwise")
                                            .font(NurturTypography.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.glass)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal)
                                    .transition(.blurReplace)
                                }
                            }

                            // Anchor — used for auto-scroll-to-bottom on each new turn / response.
                            Color.clear
                                .frame(height: 1)
                                .id("assist.bottom")
                        }
                        .padding(.vertical, 12)
                        .animation(.spring(duration: 0.5, bounce: 0.15), value: viewModel.turns.count)
                        .animation(.spring(duration: 0.4, bounce: 0.15), value: viewModel.isStreaming)
                        .animation(.spring(duration: 0.4, bounce: 0.15), value: viewModel.turns.last?.response == nil)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollEdgeEffectStyle(.soft, for: .all)
                    .onChange(of: viewModel.turns.count) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.turns.last?.response == nil) { _, _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.isStreaming) { _, _ in
                        scrollToBottom(proxy)
                    }
                }

                // Input bar
                if !viewModel.emergencyMode {
                    HStack(spacing: 12) {
                        TextField(Strings.Assist.inputPlaceholder, text: $viewModel.query, axis: .vertical)
                            .lineLimit(1...4)
                            .textFieldStyle(.plain)
                            .focused($isInputFocused)
                            .disabled(viewModel.isStreaming)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)

                        Button {
                            isInputFocused = false
                            Task { await viewModel.ask(baby: baby) }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    .white,
                                    sendDisabled ? NurturColors.textFaint.opacity(0.3) : NurturColors.accent
                                )
                                .scaleEffect(sendDisabled ? 1.0 : 1.05)
                                .animation(.easeInOut(duration: 0.2), value: sendDisabled)
                        }
                        .disabled(sendDisabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

/// One conversation row: the parent's question bubble + the AI reply (or
/// inline loading / inline error / inline doctor banner) underneath. Kept
/// private to AssistView since it only makes sense inside this layout.
private struct AssistTurnView: View {
    let turn: AssistTurn
    let isLatest: Bool
    let isStreaming: Bool
    let showDoctorBanner: Bool
    let onFeedback: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Right-aligned question bubble. Tinted with a soft accent so
            // the parent's voice reads as "yours" against the AI's neutral
            // reassurance card below.
            HStack {
                Spacer(minLength: 32)
                Text(turn.question)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(NurturColors.accentSoft, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(NurturColors.accent.opacity(0.18), lineWidth: 0.5)
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal)

            // Pre-response doctor banner — attached to the in-flight turn so
            // it sits visually with the question that triggered it.
            if showDoctorBanner {
                EscalationBannerView(
                    isEmergency: false,
                    callDoctorItems: [Strings.Assist.doctorEscalation]
                )
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let response = turn.response {
                AIResponseView(
                    response: response,
                    wasHelpful: turn.wasHelpful,
                    onFeedback: turn.insightID == nil ? nil : onFeedback
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .offset(y: 12)))
            } else if let errorMessage = turn.errorMessage {
                Text(errorMessage)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.danger)
                    .padding(.horizontal)
                    .transition(.opacity)
            } else if isLatest && isStreaming {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(NurturColors.accent)
                    Text(Strings.Assist.loadingMessage)
                        .font(NurturTypography.subheadline)
                        .foregroundStyle(NurturColors.textFaint)
                }
                .padding(.horizontal)
                .transition(.blurReplace)
            }
        }
    }
}
