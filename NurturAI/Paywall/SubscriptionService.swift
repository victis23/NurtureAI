import Foundation
import StoreKit

protocol SubscriptionServiceProtocol {
    var isSubscribed: Bool { get }
    func purchase(product: NurturProduct) async throws
    func restorePurchases() async throws
}

enum NurturProduct: String, CaseIterable {
    case proMonthly   = "com.uathelp.nurturAI.pro.monthly"
    case proAnnual    = "com.uathelp.nurturAI.pro.annual"
    case familyAnnual = "com.uathelp.nurturAI.family.annual"

    var displayName: String {
        switch self {
        case .proMonthly:   return "Pro Monthly"
        case .proAnnual:    return "Pro Annual"
        case .familyAnnual: return "Family Annual"
        }
    }

    var price: String {
        switch self {
        case .proMonthly:   return "$14.99/mo"
        case .proAnnual:    return "$99.00/yr"
        case .familyAnnual: return "$149.00/yr"
        }
    }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:    return "Product not found. Please try again later."
        case .verificationFailed: return "Purchase could not be verified."
        case .pending:            return "Your purchase is pending approval."
        case .unknown:            return "An unknown error occurred."
        }
    }
}

@MainActor
@Observable
final class StoreKitSubscriptionService: SubscriptionServiceProtocol {
    var isSubscribed: Bool = false

    private var storeProducts: [String: Product] = [:]
    private var transactionListenerTask: Task<Void, Never>?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func start() {
        transactionListenerTask = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.refreshSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
        Task { await loadProducts() }
        Task { await refreshSubscriptionStatus() }
    }

    func purchase(product nurturProduct: NurturProduct) async throws {
        guard let product = storeProducts[nurturProduct.rawValue] else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshSubscriptionStatus()
            await transaction.finish()
        case .userCancelled:
            return
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    private func loadProducts() async {
        let ids = NurturProduct.allCases.map(\.rawValue)
        guard let products = try? await Product.products(for: ids) else { return }
        for product in products {
			storeProducts[product.id] = product
        }
    }

    private func refreshSubscriptionStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                hasActive = true
                break
            }
        }
        isSubscribed = hasActive
        appState.isSubscribed = hasActive
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw SubscriptionError.verificationFailed
        case .verified(let value): return value
        }
    }
}
