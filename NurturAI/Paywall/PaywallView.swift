import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appContainer) private var container

    @State private var isPurchasing: Bool = false
    @State private var inlineError: String?
    @State private var restoreMessage: String?
    @State private var showPrivacyPolicy: Bool = false
    @State private var showTermsOfUse: Bool = false
	var isOnboarding: Bool = false

    var body: some View {
		if isOnboarding {
			contentBody
		} else {
			NavigationStack {
				contentBody
					.navigationTitle(Strings.Paywall.navigationTitle)
			}
		}
    }
	
	private var contentBody: some View {
		ScrollView {
			GlassEffectContainer {
				VStack(spacing: 20) {
					header

					// Product cards area — replaced by a loader / error view
					// while StoreKit is still fetching.
					if let service = container?.subscriptionService {
						productsSection(service: service)
					}

					VStack(spacing: 12) {
						if let inlineError {
							Text(inlineError)
								.font(NurturTypography.caption)
								.foregroundStyle(NurturColors.danger)
								.multilineTextAlignment(.center)
								.padding(.horizontal)
						}

						if let restoreMessage {
							Text(restoreMessage)
								.font(NurturTypography.caption)
								.foregroundStyle(NurturColors.textSecondary)
								.multilineTextAlignment(.center)
								.padding(.horizontal)
						}

						Button(Strings.Paywall.restorePurchases) {
							Task { await restore() }
						}
						.font(NurturTypography.subheadline)
						.foregroundStyle(NurturColors.textSecondary)
						.disabled(isPurchasing)

						// Apple Guideline 3.1.2(c): functional Privacy Policy + Terms of
						// Use links must be reachable from the purchase flow itself, not
						// just from Settings.
						HStack(spacing: 12) {
							Button(Strings.Paywall.privacyPolicy) { showPrivacyPolicy = true }
							Text("·")
								.foregroundStyle(NurturColors.textFaint)
							Button(Strings.Paywall.termsOfUse) { showTermsOfUse = true }
						}
						.font(NurturTypography.caption)
						.foregroundStyle(NurturColors.accent.opacity(0.85))

						Text(Strings.Paywall.footer)
							.font(NurturTypography.caption2)
							.foregroundStyle(NurturColors.textFaint)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 24)
							.padding(.bottom, 32)
					}
				}
			}
		}
		.background {
			if !isOnboarding {
				NurturAuroraBackground()
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			if !isOnboarding {
				ToolbarItem(placement: .cancellationAction) {
					Button(Strings.Common.close) { dismiss() }
					// Avoid dismissing mid-purchase — StoreKit UI is modal,
					// but the user could still tap this between the purchase
					// sheet closing and our finish() completing.
						.disabled(isPurchasing)
				}
			}
		}
		.sheet(isPresented: $showPrivacyPolicy) {
			NavigationStack {
				PrivacyPolicy()
					.toolbar {
						ToolbarItem(placement: .topBarTrailing) {
							Button(Strings.Common.done) { showPrivacyPolicy = false }
								.foregroundStyle(NurturColors.accent)
						}
					}
			}
		}
		.sheet(isPresented: $showTermsOfUse) {
			TermsAndConditions(showTermsAndConditions: $showTermsOfUse)
		}
	}

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 14) {
            GlassIconBadge(icon: "sparkles", color: NurturColors.accent, size: 64)

            Text(Strings.Paywall.title)
                .font(NurturTypography.largeTitle)
                .foregroundStyle(NurturColors.textPrimary)

            Text(Strings.Paywall.subtitle)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .nurturGlassCard(cornerRadius: 28)
        .padding(.horizontal)
        .padding(.top, 24)
    }

    @ViewBuilder
    private func productsSection(service: StoreKitSubscriptionService) -> some View {
        if service.isLoadingProducts && service.product(for: .proMonthly) == nil {
            loadingView
        } else if let loadError = service.productLoadError, service.product(for: .proMonthly) == nil {
            errorView(message: loadError, service: service)
        } else {
            productCards(service: service)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(NurturColors.accent)
            Text(Strings.Paywall.loadingProducts)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .nurturGlassCard(cornerRadius: 24)
        .padding(.horizontal)
    }

    private func errorView(message: String, service: StoreKitSubscriptionService) -> some View {
        VStack(spacing: 12) {
            GlassIconBadge(icon: "exclamationmark.triangle", color: NurturColors.danger, size: 44)

            Text(message)
                .font(NurturTypography.subheadline)
                .foregroundStyle(NurturColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(Strings.Paywall.tryAgain) {
                Task { await service.retryProductLoad() }
            }
            .font(NurturTypography.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(NurturColors.accent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .nurturGlassCardTinted(NurturColors.danger, cornerRadius: 24)
        .padding(.horizontal)
    }

    private func productCards(service: StoreKitSubscriptionService) -> some View {
        VStack(spacing: 12) {
            ProductCard(
                product: .proMonthly,
                isHighlighted: false,
                isPurchasing: isPurchasing,
                storeProduct: service.product(for: .proMonthly),
                onTap: { purchase(.proMonthly) }
            )
            ProductCard(
                product: .proAnnual,
                isHighlighted: true,
                isPurchasing: isPurchasing,
                storeProduct: service.product(for: .proAnnual),
                onTap: { purchase(.proAnnual) }
            )
            ProductCard(
                product: .familyAnnual,
                isHighlighted: false,
                isPurchasing: isPurchasing,
                storeProduct: service.product(for: .familyAnnual),
                onTap: { purchase(.familyAnnual) }
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func purchase(_ product: NurturProduct) {
        guard let service = container?.subscriptionService else { return }
        isPurchasing = true
        inlineError = nil
        restoreMessage = nil
        Task {
            do {
                try await service.purchase(product: product)
                // A successful verified purchase immediately flips isSubscribed.
                // Only auto-dismiss if we actually got access — `userCancelled`
                // returns without throwing and we want to keep the paywall open
                // in that case.
                if service.isSubscribed {
                    dismiss()
                }
            } catch {
                self.inlineError = error.localizedDescription
            }
            isPurchasing = false
        }
    }

    private func restore() async {
        guard let service = container?.subscriptionService else { return }
        inlineError = nil
        restoreMessage = nil
        do {
            try await service.restorePurchases()
            if service.lastRestoreFoundPurchases == true {
                restoreMessage = Strings.Paywall.restored
                if service.isSubscribed { dismiss() }
            } else {
                restoreMessage = Strings.Paywall.noPurchasesFound
            }
        } catch {
            inlineError = error.localizedDescription
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: NurturProduct
    let isHighlighted: Bool
    let isPurchasing: Bool
    /// Loaded StoreKit product — when present we show the localized
    /// `displayPrice`; when nil we fall back to the hardcoded price string.
    let storeProduct: Product?
    let onTap: () -> Void

    private var priceText: String {
        storeProduct?.displayPrice ?? product.price
    }

    /// Human-readable subscription period (e.g. "1 month · auto-renewing").
    /// Required by App Store Guideline 3.1.2(c). Reads from the loaded
    /// StoreKit `Product` so the value is always accurate to the
    /// configured subscription; falls back to a hardcoded label keyed off
    /// `NurturProduct` while StoreKit is still loading.
    private var lengthText: String {
        if let period = storeProduct?.subscription?.subscriptionPeriod {
            return Self.formatLength(period)
        }
        return Self.fallbackLength(for: product)
    }

    /// Per-month equivalent for multi-month plans (e.g. "≈$8.25/mo" for an
    /// annual). `nil` for monthly plans where the per-unit price *is* the
    /// price. Apple's review note specifically calls out price-per-unit
    /// disclosure where appropriate.
    private var perMonthText: String? {
        if let storeProduct,
           let period = storeProduct.subscription?.subscriptionPeriod,
           let months = Self.monthsIn(period),
           months > 1 {
            let perMonth = storeProduct.price / Decimal(months)
            return "≈\(perMonth.formatted(storeProduct.priceFormatStyle))\(Strings.Paywall.perMonthSuffix)"
        }
        return Self.fallbackPerMonth(for: product)
    }

    /// Per-plan glyph for the leading glass icon chip. Purely decorative.
    private var iconName: String {
        switch product {
        case .proMonthly:   return "calendar"
        case .proAnnual:    return "crown.fill"
        case .familyAnnual: return "figure.2.and.child.holdinghands"
        }
    }

    /// Accent rim sold as the "selected / best value" treatment.
    private var accentRim: LinearGradient {
        LinearGradient(
            colors: [NurturColors.accent, NurturColors.accent.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                GlassIconBadge(icon: iconName, color: NurturColors.accent, size: 38)

                VStack(alignment: .leading, spacing: 4) {
                    if isHighlighted {
                        Text(Strings.Paywall.bestValue)
                            .font(NurturTypography.caption2)
                            .fontWeight(.bold)
                            .kerning(0.8)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(NurturGradients.accent, in: Capsule())
                    }
                    Text(product.displayName)
                        .font(NurturTypography.headline)
                        .foregroundStyle(NurturColors.textPrimary)
                    Text(lengthText)
                        .font(NurturTypography.caption)
                        .foregroundStyle(NurturColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(priceText)
                        .font(NurturTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isHighlighted ? NurturColors.accent : NurturColors.textPrimary)
                    if let perMonthText {
                        Text(perMonthText)
                            .font(NurturTypography.caption2)
                            .foregroundStyle(NurturColors.textFaint)
                    }
                }
            }
            .padding(18)
            // Keep the whole card tappable, not just its subviews — same
            // hit-area pitfall as the card-selection fix elsewhere in the app.
            .contentShape(.rect(cornerRadius: 22, style: .continuous))
            .glassEffect(
                isHighlighted
                    ? .regular.tint(NurturColors.accent.opacity(0.14)).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        isHighlighted ? AnyShapeStyle(accentRim) : AnyShapeStyle(NurturGradients.glassRim),
                        lineWidth: isHighlighted ? 1.5 : 1
                    )
            )
            .shadow(
                color: isHighlighted ? NurturColors.accent.opacity(0.20) : .black.opacity(0.07),
                radius: 14, x: 0, y: 7
            )
        }
        // Disable taps while a purchase is in flight OR while the product
        // hasn't loaded — tapping a nil product would have thrown productNotFound.
        .disabled(isPurchasing || storeProduct == nil)
        .opacity(storeProduct == nil ? 0.5 : 1.0)
    }

    // MARK: - Period formatting helpers

    private static func formatLength(_ period: Product.SubscriptionPeriod) -> String {
        let unitWord: String
        switch period.unit {
        case .day:    unitWord = period.value == 1 ? "day"   : "days"
        case .week:   unitWord = period.value == 1 ? "week"  : "weeks"
        case .month:  unitWord = period.value == 1 ? "month" : "months"
        case .year:   unitWord = period.value == 1 ? "year"  : "years"
        @unknown default: return Strings.Paywall.autoRenewSuffix
        }
        return "\(period.value) \(unitWord) · \(Strings.Paywall.autoRenewSuffix)"
    }

    private static func monthsIn(_ period: Product.SubscriptionPeriod) -> Int? {
        switch period.unit {
        case .month: return period.value
        case .year:  return period.value * 12
        case .day, .week: return nil
        @unknown default: return nil
        }
    }

    private static func fallbackLength(for product: NurturProduct) -> String {
        switch product {
        case .proMonthly:   return "1 month · \(Strings.Paywall.autoRenewSuffix)"
        case .proAnnual:    return "1 year · \(Strings.Paywall.autoRenewSuffix)"
        case .familyAnnual: return "1 year · \(Strings.Paywall.autoRenewSuffix)"
        }
    }

    private static func fallbackPerMonth(for product: NurturProduct) -> String? {
        // Hardcoded fallbacks mirror Strings.Products.* prices so they read
        // correctly even before StoreKit returns. Once the real product
        // loads, the dynamic computation above takes over.
        switch product {
        case .proMonthly:   return nil
        case .proAnnual:    return "≈$8.25\(Strings.Paywall.perMonthSuffix)"
        case .familyAnnual: return "≈$12.42\(Strings.Paywall.perMonthSuffix)"
        }
    }
}

struct previewT: PreviewProvider {
	static var previews: some View {
		
	}
}
