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
		.nurturGlassCard(cornerRadius: 22)
        .scaleEffect(pulseScale)
        .shadow(color: isUrgent ? Color.red.opacity(0.35) : .clear, radius: 8)
        // Scoped to `pulseScale` so the urgent breathing can't leak onto a shared
        // transaction — the same imperative withAnimation(.repeatForever) trap that
        // made Home's timer widget bounce when feed was started from the Log tab.
        .animation(
            isUrgent
                ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                : .easeInOut(duration: 0.3),
            value: pulseScale
        )
        .onAppear { pulseScale = isUrgent ? 1.02 : 1.0 }
        .onChange(of: isUrgent) { _, newValue in pulseScale = newValue ? 1.02 : 1.0 }
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
        .nurturGlassCard(cornerRadius: 22)
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
            .nurturGlassRow(cornerRadius: 18)
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
                .pillButton(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .animation(NurturMotion.spring, value: isSelected)
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
            .foregroundStyle(color)
            .glassEffect(
                .regular.tint(color.opacity(0.16)).interactive(),
                in: .rect(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(NurturGradients.glassRim, lineWidth: 1)
            )
            .shadow(color: color.opacity(0.10), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .nurturPressable()
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
                .glassEffect(.regular, in: .capsule)
                .overlay(Capsule().strokeBorder(NurturGradients.glassRim, lineWidth: 0.8))
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
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
                .fill(
                    LinearGradient(
                        colors: [NurturColors.accentSoft, NurturColors.accentSoft.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [NurturColors.accent.opacity(0.55), NurturColors.accent.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(NurturColors.accent)
        }
        .shadow(color: NurturColors.accent.opacity(0.15), radius: 6, x: 0, y: 3)
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
            .nurturGlassCardTinted(NurturColors.warning, cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .nurturPressable()
    }
}

// MARK: - Parenting Score

extension ParentingScore.Tone {
    var solid: Color {
        switch self {
        case .good:    NurturColors.success
        case .caution: NurturColors.warning
        case .danger:  NurturColors.danger
        }
    }

    var soft: Color {
        switch self {
        case .good:    NurturColors.success.opacity(0.16)
        case .caution: NurturColors.warning.opacity(0.16)
        case .danger:  NurturColors.danger.opacity(0.14)
        }
    }
}

/// 270° arc gauge replicating the mockup: a faint full track plus a
/// terracotta→amber→green fill trimmed to `score/100` of the arc. The 90°
/// gap sits at the bottom (a 0.75 trim rotated 135°).
struct ScoreGauge: View {
    let score: Int
    var size: CGFloat = 118
    var lineWidth: CGFloat = 12
    var showSubtitle: Bool = true

    private var fraction: CGFloat { CGFloat(max(0, min(100, score))) / 100 }

    private let arc = Gradient(colors: [
        Color(red: 0.78, green: 0.29, blue: 0.17),  // terracotta
        Color(red: 0.88, green: 0.64, blue: 0.24),  // amber
        Color(red: 0.37, green: 0.63, blue: 0.42)   // green
    ])

    private var numberColor: Color {
        if score >= 75 { return NurturColors.success }
        if score >= 45 { return NurturColors.warning }
        return NurturColors.danger
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(NurturColors.textPrimary.opacity(0.10),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0, to: 0.75 * fraction)
                .stroke(AngularGradient(gradient: arc,
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))
                .animation(.easeOut(duration: 0.8), value: fraction)
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(numberColor)
                    .contentTransition(.numericText())
                if showSubtitle {
                    Text("/ 100")
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textFaint)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct ParentingScoreCard: View {
    let score: ParentingScore
    var showBackground: Bool = true

    var body: some View {
        if showBackground {
            cardContent
                .nurturGlassCard(cornerRadius: 22)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(spacing: 14) {
            ScoreGauge(score: score.value)

            Text(score.pill)
                .font(NurturTypography.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(score.pillTone.soft, in: Capsule())
                .foregroundStyle(score.pillTone.solid)

            Text(score.heading)
                .font(NurturTypography.headline)
                .foregroundStyle(NurturColors.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ForEach(score.chips) { chip in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(chip.tone.solid)
                            .frame(width: 7, height: 7)
                        Text(chip.label)
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(chip.tone.soft, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
}
