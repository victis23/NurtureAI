import SwiftUI

// MARK: - Nurtur Liquid Glass Design Language
//
// The shared visual vocabulary for the app's liquid-glass revamp. Every screen
// composes these primitives so glass depth, corner radii, motion and ambient
// color stay consistent app-wide.
//
//   Radii   — 28 hero · 24 card · 18 row · capsule pills
//   Motion  — NurturMotion.spring for state, .snappy for presses
//   Layers  — ambient aurora background → glass cards → glass pills/buttons

// MARK: - Motion

enum NurturMotion {
    /// Standard state-change spring (expand/collapse, selection, layout).
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.85)
    /// Quick press/tap feedback.
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.75)
    /// Gentle entrance for content appearing on screen.
    static let gentle = Animation.spring(response: 0.55, dampingFraction: 0.9)
}

// MARK: - Gradients

enum NurturGradients {
    /// Primary CTA fill — warm terracotta sweep.
    static let accent = LinearGradient(
        colors: [NurturColors.accent, NurturColors.accent.opacity(0.82)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Hairline edge highlight that sells the "lit glass rim" look.
    static let glassRim = LinearGradient(
        stops: [
            .init(color: .white.opacity(0.45), location: 0),
            .init(color: .white.opacity(0.06), location: 0.45),
            .init(color: .white.opacity(0.18), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Ambient Aurora Background

/// The app-wide screen backdrop: warm cream base with three oversized,
/// heavily-blurred color blobs that drift on a slow loop. Sits *behind*
/// glass surfaces so `glassEffect` has something soft to refract.
struct NurturAuroraBackground: View {
    var animated: Bool = true
    @State private var drift = false

    var body: some View {
        ZStack {
            NurturColors.background

            Circle()
                .fill(NurturColors.accent.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: drift ? -110 : -60, y: drift ? -240 : -180)

            Circle()
                .fill(NurturColors.info.opacity(0.10))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: drift ? 150 : 110, y: drift ? -40 : 30)

            Circle()
                .fill(NurturColors.success.opacity(0.08))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: drift ? -70 : -20, y: drift ? 300 : 360)
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Standard screen backdrop for every top-level view.
    func nurturScreenBackground(animated: Bool = true) -> some View {
        background(NurturAuroraBackground(animated: animated))
    }
}

// MARK: - Glass Surfaces

extension View {
    /// Standard glass card: regular glass + lit rim + soft floating shadow.
    func nurturGlassCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(NurturGradients.glassRim, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 7)
    }

    /// Tinted glass card for semantic emphasis (warnings, success states).
    func nurturGlassCardTinted(_ tint: Color, cornerRadius: CGFloat = 24) -> some View {
        self
            .glassEffect(.regular.tint(tint.opacity(0.14)), in: .rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.12), radius: 12, x: 0, y: 6)
    }

    /// Compact glass row (timeline entries, list rows).
    func nurturGlassRow(cornerRadius: CGFloat = 18) -> some View {
        self
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(NurturGradients.glassRim, lineWidth: 0.8)
            )
    }

    /// Interactive glass capsule (chips, pills, small buttons) — responds to
    /// touch with the system's liquid press shimmer.
    func nurturGlassPill() -> some View {
        self
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay(Capsule().strokeBorder(NurturGradients.glassRim, lineWidth: 0.8))
    }
}

// MARK: - Pressable

private struct NurturPressableModifier: ViewModifier {
    @GestureState private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.965 : 1)
            .animation(NurturMotion.snappy, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($pressed) { _, state, _ in state = true }
            )
    }
}

extension View {
    /// Spring scale-down on touch for non-Button tappables.
    func nurturPressable() -> some View {
        modifier(NurturPressableModifier())
    }
}

// MARK: - Icon Badge

/// Rounded-square icon chip used across cards, rows and headers.
struct GlassIconBadge: View {
    let icon: String
    var color: Color = NurturColors.accent
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                color.opacity(0.16),
                in: RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .strokeBorder(color.opacity(0.18), lineWidth: 0.8)
            )
    }
}

// MARK: - Section Header

/// Shared eyebrow header for content sections ("AT A GLANCE", "TIMELINE"…).
struct NurturSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(NurturGradients.accent)
                .frame(width: 6, height: 6)
            Text(title)
                .font(NurturTypography.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .kerning(1.1)
                .foregroundStyle(NurturColors.textSecondary)
            Spacer()
        }
        .padding(.leading, 4)
    }
}
