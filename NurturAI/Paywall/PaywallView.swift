import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContainer) private var container
    @State private var isPurchasing: Bool = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 56))
                            .foregroundStyle(NurturColors.accent)

                        Text(Strings.Paywall.title)
                            .font(NurturTypography.largeTitle)
                            .foregroundStyle(NurturColors.textPrimary)

                        Text(Strings.Paywall.subtitle)
                            .font(NurturTypography.subheadline)
                            .foregroundStyle(NurturColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 12) {
                        ProductCard(
                            product: .proMonthly,
                            isHighlighted: false,
                            isPurchasing: isPurchasing,
                            onTap: { purchase(.proMonthly) }
                        )
                        ProductCard(
                            product: .proAnnual,
                            isHighlighted: true,
                            isPurchasing: isPurchasing,
                            onTap: { purchase(.proAnnual) }
                        )
                        ProductCard(
                            product: .familyAnnual,
                            isHighlighted: false,
                            isPurchasing: isPurchasing,
                            onTap: { purchase(.familyAnnual) }
                        )
                    }
                    .padding(.horizontal)

                    if let error {
                        Text(error)
                            .font(NurturTypography.caption)
                            .foregroundStyle(NurturColors.danger)
                    }

                    Button(Strings.Paywall.restorePurchases) {
                        Task { await restore() }
                    }
                    .font(NurturTypography.subheadline)
                    .foregroundStyle(NurturColors.textSecondary)

                    Text(Strings.Paywall.footer)
                        .font(NurturTypography.caption2)
                        .foregroundStyle(NurturColors.textFaint)
                        .padding(.bottom, 32)
                }
            }
            .background(NurturColors.background)
            .navigationTitle(Strings.Paywall.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.close) { dismiss() }
                }
            }
        }
    }

    private func purchase(_ product: NurturProduct) {
        guard let service = container?.subscriptionService else { return }
        isPurchasing = true
        error = nil
        Task {
            do {
                try await service.purchase(product: product)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func restore() async {
        guard let service = container?.subscriptionService else { return }
        do {
            try await service.restorePurchases()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct ProductCard: View {
    let product: NurturProduct
    let isHighlighted: Bool
    let isPurchasing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isHighlighted {
                        Text(Strings.Paywall.bestValue)
                            .font(NurturTypography.caption2)
                            .foregroundStyle(NurturColors.accent)
                            .fontWeight(.bold)
                    }
                    Text(product.displayName)
                        .font(NurturTypography.headline)
                        .foregroundStyle(NurturColors.textPrimary)
                }
                Spacer()
                Text(product.price)
                    .font(NurturTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isHighlighted ? NurturColors.accent : NurturColors.textPrimary)
            }
            .padding(16)
            .background(
                isHighlighted ? NurturColors.accentSoft : NurturColors.surface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isHighlighted ? NurturColors.accent : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isPurchasing)
    }
}
