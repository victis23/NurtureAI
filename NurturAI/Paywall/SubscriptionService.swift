import Foundation

protocol SubscriptionServiceProtocol {
    var isSubscribed: Bool { get }
    func purchase(product: NurturProduct) async throws
    func restorePurchases() async throws
}

enum NurturProduct: String {
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

final class StubSubscriptionService: SubscriptionServiceProtocol {
    var isSubscribed: Bool { false }
    func purchase(product: NurturProduct) async throws {}
    func restorePurchases() async throws {}
}
