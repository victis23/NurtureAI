import SwiftUI

struct OnboardingPreviewStepView: View {
    let draft: OnboardingViewModel.OnboardingDraft

    @State private var preview: OnboardingPreview?
    @State private var phase: Phase = .loading
    @State private var pulse: Bool = false

    private enum Phase { case loading, loaded }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.Onboarding.AIPreview.heading)
                    .font(NurturTypography.title2)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.AIPreview.subheading)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
            }

            switch phase {
            case .loading:  loadingState
            case .loaded:   loadedState
            }
        }
        .task {
            await loadPreview()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(NurturColors.accent)
                .scaleEffect(pulse ? 1.15 : 0.9)
                .opacity(pulse ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }

            VStack(spacing: 4) {
                Text(Strings.Onboarding.AIPreview.loadingTitle)
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(Strings.Onboarding.AIPreview.loadingSubtitle)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    @ViewBuilder
    private var loadedState: some View {
        if let preview {
            VStack(alignment: .leading, spacing: 16) {
                GreetingCard(text: preview.greeting)

                VStack(spacing: 12) {
                    ForEach(preview.focuses) { focus in
                        FocusCard(focus: focus)
                    }
                }

                ReassuranceCard(text: preview.reassurance)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Networking

    /// Pre-flight connectivity check decides whether we hit the live AI path
    /// or use the local fallback. If we're online but the call still fails
    /// (e.g. flaky cell signal mid-call, server hiccup), we silently swap to
    /// the fallback so the user never lands on a broken state.
    private func loadPreview() async {
        let result: OnboardingPreview

        if await NetworkChecker.isOnline() {
            do {
                result = try await OnboardingPreviewService().generate(draft: draft)
            } catch {
                result = OnboardingPreviewFallback.make(draft: draft)
            }
        } else {
            result = OnboardingPreviewFallback.make(draft: draft)
        }

        withAnimation(.easeOut(duration: 0.4)) {
            preview = result
            phase = .loaded
        }
    }
}

// MARK: - Cards

private struct GreetingCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(NurturTypography.body)
            .foregroundStyle(NurturColors.textPrimary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassEffect(
                .regular.tint(NurturColors.accent.opacity(0.6)),
                in: RoundedRectangle(cornerRadius: 16)
            )
    }
}

private struct FocusCard: View {
    let focus: PreviewFocus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NurturColors.accent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(focus.title)
                    .font(NurturTypography.headline)
                    .foregroundStyle(NurturColors.textPrimary)
                Text(focus.detail)
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReassuranceCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(NurturColors.accent)
                .padding(.top, 2)
            Text(text)
                .font(NurturTypography.callout)
                .foregroundStyle(NurturColors.textPrimary)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}
