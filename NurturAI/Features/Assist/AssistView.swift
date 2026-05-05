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

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Emergency banner
                        if viewModel.emergencyMode {
                            EscalationBannerView(isEmergency: true, callDoctorItems: [])
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Doctor banner (pre-response)
                        if viewModel.showEscalationBanner && !viewModel.emergencyMode && viewModel.parsedResponse == nil {
                            EscalationBannerView(
                                isEmergency: false,
                                callDoctorItems: [Strings.Assist.doctorEscalation]
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !viewModel.emergencyMode {
                            // Quick picks
                            if viewModel.parsedResponse == nil && !viewModel.isStreaming {
                                QuickPicksView { pick in
                                    viewModel.query = pick
                                    isInputFocused = true
                                }
                                .padding(.top, 8)
                                .transition(.blurReplace)
                            }

                            // Loading indicator
                            if viewModel.isStreaming {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .controlSize(.regular)
                                        .tint(NurturColors.accent)
                                    Text(Strings.Assist.loadingMessage)
                                        .font(NurturTypography.subheadline)
                                        .foregroundStyle(NurturColors.textFaint)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                                .transition(.blurReplace)
                            }

                            // Parsed response
                            if let response = viewModel.parsedResponse {
                                AIResponseView(
                                    response: response,
                                    insight: nil,
                                    insightRepository: container?.insightRepository
                                )
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .offset(y: 20)))

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
                                .padding(.horizontal)
                                .transition(.blurReplace)
                            }

                            // Error
                            if let error = viewModel.error {
                                Text(error.errorDescription ?? Strings.Assist.errorFallback)
                                    .font(NurturTypography.subheadline)
                                    .foregroundStyle(NurturColors.danger)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .animation(.spring(duration: 0.5, bounce: 0.15), value: viewModel.parsedResponse == nil)
                    .animation(.spring(duration: 0.4, bounce: 0.15), value: viewModel.isStreaming)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollEdgeEffectStyle(.soft, for: .all)

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
