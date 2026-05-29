import SwiftUI

// MARK: - Status Card

struct NurturStatusCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    /// When true, the card pulses gently and gains a faint red glow. Used on
    /// Home to draw the parent's eye to severely overdue feed/sleep/diaper.
    let isUrgent: Bool

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = NurturColors.accent,
        isUrgent: Bool = false
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.isUrgent = isUrgent
    }

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(NurturTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(NurturColors.textSecondary)
            }
            Text(value)
                .font(NurturTypography.title3)
                .foregroundStyle(NurturColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let subtitle {
                Text(subtitle)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
		.padding(16)
		.frame(height: 112, alignment: .topLeading)
		.glassEffect(.regular, in: .rect(cornerRadius: 22))
		.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(pulseScale)
        .shadow(color: isUrgent ? Color.red.opacity(0.35) : .clear, radius: 8)
        .onAppear { applyPulseState(isUrgent) }
        .onChange(of: isUrgent) { _, newValue in applyPulseState(newValue) }
    }

    private func applyPulseState(_ urgent: Bool) {
        if urgent {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.02
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                pulseScale = 1.0
            }
        }
    }
}

// MARK: - Shimmer

/// A sweeping highlight that animates across whatever it's applied to,
/// giving skeleton placeholders a "loading" feel rather than a static block.
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(color: NurturColors.accent.opacity(0.85), location: 0.5),
                            .init(color: .clear, location: 0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: geo.size.width * phase)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func nurturShimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

/// A rounded block used as a building element inside skeleton layouts. Filled
/// with a soft left-to-right gradient and a moving highlight sweep so each one
/// reads as a shimmering placeholder rather than a flat grey box.
struct NurturSkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        NurturColors.accent.opacity(0.15),
                        NurturColors.accent.opacity(0.38),
                        NurturColors.accent.opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .nurturShimmer()
    }
}

// MARK: - Status Card Skeleton

/// Placeholder matching `NurturStatusCard`'s footprint (112pt tall, same glass
/// styling) so the "At a glance" grid reserves its space while data loads.
struct NurturStatusCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                NurturSkeletonBlock(width: 24, height: 24, cornerRadius: 8)
                NurturSkeletonBlock(width: 56, height: 10, cornerRadius: 5)
            }
            NurturSkeletonBlock(width: 80, height: 18, cornerRadius: 6)
            NurturSkeletonBlock(width: 48, height: 10, cornerRadius: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 112, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Timeline Row Skeleton

/// Placeholder matching `TimelineEventRow`'s layout so the timeline reserves
/// its space while logs load instead of flashing the empty-state card.
struct NurturTimelineRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NurturSkeletonBlock(width: 34, height: 34, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    NurturSkeletonBlock(width: 80, height: 12, cornerRadius: 6)
                    Spacer()
                    NurturSkeletonBlock(width: 40, height: 10, cornerRadius: 5)
                }
                NurturSkeletonBlock(width: 120, height: 10, cornerRadius: 5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - Timer Display

struct TimerDisplay: View {
    let elapsed: TimeInterval
    var isRunning: Bool = true

    var body: some View {
        Text(formatElapsed(elapsed))
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .foregroundStyle(isRunning ? NurturColors.accent : NurturColors.textSecondary)
            .contentTransition(.numericText())
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Pill Button

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NurturTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(
                    isSelected ? NurturColors.accent : NurturColors.surfaceWarm,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : NurturColors.textPrimary)
        }
    }
}

// MARK: - Large Action Button

struct LargeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))

                Text(title)
                    .font(NurturTypography.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .foregroundStyle(color)
			.overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
				.strokeBorder(.white, lineWidth: 1.5).opacity(0.6))
        }
    }
}

// MARK: - Toast Overlay

struct ToastOverlay: View {
    let message: String
    let isShowing: Bool

    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(NurturColors.success)
                    Text(message)
                        .font(NurturTypography.subheadline)
                        .foregroundStyle(NurturColors.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 20)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
    }
}

// MARK: - Baby Avatar

struct BabyAvatar: View {
    let name: String
    var size: CGFloat = 56

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(NurturColors.accentSoft)
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(NurturColors.accent)
        }
    }
}

// MARK: - Prediction Card

struct PredictionCard: View {
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(NurturColors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NurturTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(NurturColors.textPrimary)
                    Text(message)
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }
            .padding(14)
            .background(NurturColors.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(NurturColors.warning.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
