import SwiftUI
import Lottie

/// Root-level overlay that plays a one-shot confetti Lottie when something
/// celebration-worthy happens (first onboarding completion, successful
/// subscription). Sets `trigger` back to nil after the animation so the same
/// binding can be re-fired later.
///
/// Doesn't block touches — the user can keep interacting with whatever's
/// underneath (HomeView, paywall, etc.) while the confetti rains down.
struct ConfettiOverlayView: View {
    @Binding var trigger: UUID?

    /// Lottie file is "Confetti - Full Screen.json" (~2.5s). 3 seconds gives
    /// the animation time to settle before we tear the view down.
    private let displayDuration: Duration = .seconds(3)

    var body: some View {
        if let id = trigger {
            LottieView(animation: .named("Confetti - Full Screen"))
                .playing(loopMode: .playOnce)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .id(id)
                .task(id: id) {
                    try? await Task.sleep(for: displayDuration)
                    withAnimation(.easeOut(duration: 0.4)) {
                        trigger = nil
                    }
                }
        }
    }
}
