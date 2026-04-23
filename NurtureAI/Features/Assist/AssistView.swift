import SwiftUI
import SwiftData

struct AssistView: View {
    var initialQuery: String? = nil

    @Environment(AppState.self) private var appState
    @Environment(\.appContainer) private var container
    @Query(sort: \Baby.createdAt) private var babies: [Baby]
    @State private var viewModel: AssistViewModel?

    var body: some View {
            Group {
                if let baby = babies.first, let vm = viewModel {
                    AssistContentView(viewModel: vm, baby: baby, container: container)
                } else if babies.isEmpty {
                    ContentUnavailableView("No baby profile", systemImage: "bubble.left.and.bubble.right")
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Ask NurturAI")
			.task {
				guard let baby = babies.first, let container else { return }
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

    var body: some View {
        VStack(spacing: 0) {
            // Baby chip
            HStack {
                Text("\(baby.name) · \(baby.displayAge)")
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(NurturColors.surfaceWarm, in: Capsule())
                Spacer()

                if !viewModel.appState.isSubscribed {
                    Text("\(max(0, 3 - viewModel.dailyQueryCount)) free left")
                        .font(NurturTypography.caption2)
                        .foregroundStyle(NurturColors.textFaint)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Emergency banner
                    if viewModel.emergencyMode {
                        EscalationBannerView(isEmergency: true, callDoctorItems: [])
                            .padding(.horizontal)
                    }

                    // Doctor banner (pre-response)
                    if viewModel.showEscalationBanner && !viewModel.emergencyMode && viewModel.parsedResponse == nil {
                        EscalationBannerView(
                            isEmergency: false,
                            callDoctorItems: ["This question may relate to a condition worth discussing with your pediatrician."]
                        )
                        .padding(.horizontal)
                    }

                    if !viewModel.emergencyMode {
                        // Quick picks (only when no response)
                        if viewModel.parsedResponse == nil && !viewModel.isStreaming {
                            QuickPicksView { pick in
                                viewModel.query = pick
                                isInputFocused = true
                            }
                            .padding(.top, 8)
                        }

                        // Loading indicator
                        if viewModel.isStreaming {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Looking into this…")
                                    .font(NurturTypography.subheadline)
                                    .foregroundStyle(NurturColors.textFaint)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                        }

                        // Parsed response
                        if let response = viewModel.parsedResponse {
                            AIResponseView(
                                response: response,
                                insight: nil,
                                insightRepository: container?.insightRepository
                            )
                            .padding(.horizontal)

                            Button("Ask another question") {
                                viewModel.clearQuery()
                            }
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.accent)
                            .padding(.horizontal)
                        }

                        // Error
                        if let error = viewModel.error {
                            Text(error.errorDescription ?? "An error occurred.")
                                .font(NurturTypography.subheadline)
                                .foregroundStyle(NurturColors.danger)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            // Input bar
            if !viewModel.emergencyMode {
                Divider()
                HStack(spacing: 12) {
                    TextField("Describe what's happening right now...", text: $viewModel.query, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .disabled(viewModel.isStreaming)

                    Button {
                        isInputFocused = false
                        Task { await viewModel.ask(baby: baby) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? NurturColors.textFaint
                                    : NurturColors.accent
                            )
                    }
                    .disabled(viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isStreaming)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.regularMaterial)
            }
        }
        .background(NurturColors.background)
    }
}

