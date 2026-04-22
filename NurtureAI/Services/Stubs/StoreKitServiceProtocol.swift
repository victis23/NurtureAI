import Foundation

// MARK: - Week 4 Stub: StoreKit 2 in-app purchases

protocol StoreKitServiceProtocol {
    var isPremium: Bool { get }
    func fetchProducts() async throws -> [StoreProduct]
    func purchase(_ product: StoreProduct) async throws -> PurchaseResult
    func restorePurchases() async throws
}

struct StoreProduct {
    let id: String
    let displayName: String
    let displayPrice: String
    let type: ProductType

    enum ProductType {
        case monthlySubscription
        case annualSubscription
        case lifetime
    }
}

enum PurchaseResult {
    case success
    case pending
    case cancelled
    case failed(Error)
}

// Stub — replace with StoreKit 2 implementation in Week 4
final class StubStoreKitService: StoreKitServiceProtocol {
    var isPremium: Bool { false }
    func fetchProducts() async throws -> [StoreProduct] { [] }
    func purchase(_ product: StoreProduct) async throws -> PurchaseResult { .cancelled }
    func restorePurchases() async throws {}
}
