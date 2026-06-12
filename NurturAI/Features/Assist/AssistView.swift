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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .nurturScreenBackground()
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

    private func scrollTurnIntoView(_ id: UUID, proxy: ScrollViewProxy) {
        // Defer one runloop so the just-appended turn is in the hierarchy
        // before we ask SwiftUI to scroll to it. Without this, the scroll
        // target is sometimes the pre-update layout and the new turn lands
        // off-screen.
        DispatchQueue.main.async {
            withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    var body: some View {
        // Backdrop comes from .nurturScreenBackground() applied by AssistView,
        // so glass surfaces here have the shared aurora to refract.
        ZStack {
            VStack(spacing: 0) {
                // Baby chip bar
                GlassEffectContainer(spacing: 12) {
                    HStack {
                        Text("\(baby.name) · \(baby.displayAge)")
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .nurturGlassPill()

                        Spacer()

                        if !viewModel.appState.isSubscribed {
                            Text("\(max(0, 3 - viewModel.dailyQueryCount)) \(Strings.Assist.freeLeft)")
                                .font(NurturTypography.caption2)
                                .foregroundStyle(NurturColors.textFaint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .nurturGlassPill()
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

                        }
                        .padding(.vertical, 12)
                        .animation(.spring(duration: 0.5, bounce: 0.15), value: viewModel.turns.count)
                        .animation(.spring(duration: 0.4, bounce: 0.15), value: viewModel.isStreaming)
                        .animation(.spring(duration: 0.4, bounce: 0.15), value: viewModel.turns.last?.response == nil)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollEdgeEffectStyle(.soft, for: .all)
                    // Only auto-scroll when the user just sent a new question:
                    // park their question at the TOP of the viewport so the
                    // loader / response renders below it. We deliberately
                    // do NOT scroll on response arrival or `isStreaming`
                    // changes — that lets the parent read at their own pace
                    // without the view yanking them around mid-scroll.
                    .onChange(of: viewModel.turns.count) { oldCount, newCount in
                        guard newCount > oldCount,
                              let latestID = viewModel.turns.last?.id
                        else { return }
                        scrollTurnIntoView(latestID, proxy: proxy)
                    }
                }

                // Input bar — glass capsule with a prominent round send button.
                if !viewModel.emergencyMode {
                    HStack(spacing: 10) {
                        TextField(Strings.Assist.inputPlaceholder, text: $viewModel.query, axis: .vertical)
                            .font(NurturTypography.subheadline)
                            .lineLimit(1...4)
                            .textFieldStyle(.plain)
                            .focused($isInputFocused)
                            .disabled(viewModel.isStreaming)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)

                        Button {
                            isInputFocused = false
                            Task { await viewModel.ask(baby: baby) }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                        .tint(NurturColors.accent)
                        .disabled(sendDisabled)
                        .animation(.easeInOut(duration: 0.2), value: sendDisabled)
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 8)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: .capsule)
                    .overlay(Capsule().strokeBorder(NurturGradients.glassRim, lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 16)
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
                    .nurturGlassCardTinted(NurturColors.accent, cornerRadius: 18)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .nurturGlassCardTinted(NurturColors.danger, cornerRadius: 18)
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .nurturGlassPill()
                .padding(.horizontal)
                .transition(.blurReplace)
            }
        }
    }
}
