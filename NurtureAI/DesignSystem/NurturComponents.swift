import SwiftUI

// MARK: - Status Card

struct NurturStatusCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, iconColor: Color = NurturColors.accent) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textSecondary)
            }
            Text(value)
                .font(NurturTypography.title3)
                .foregroundStyle(NurturColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(NurturTypography.caption)
                    .foregroundStyle(NurturColors.textFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .nurturCardPadded()
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(NurturTypography.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(color)
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
