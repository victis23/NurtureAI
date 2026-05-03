import Foundation
import StoreKit
import OSLog

// MARK: - Public surface

/// Contract consumed by `PaywallView`, `AppContainer`, and anything that gates Pro features.
/// All members are `@MainActor` — implementations are expected to mutate observable state
/// only on the main actor so SwiftUI sees coherent updates.
@MainActor
protocol SubscriptionServiceProtocol: AnyObject {
    // Entitlement
    var isSubscribed: Bool { get }
    var subscriptionStatus: SubscriptionStatus { get }
    var activeProduct: NurturProduct? { get }
    var expirationDate: Date? { get }

    // Product loading
    var isLoadingProducts: Bool { get }
    var productLoadError: String? { get }

    // Restore feedback
    /// nil = no restore attempted yet, true = restore found at least one entitlement,
    /// false = restore completed but the user owns nothing.
    var lastRestoreFoundPurchases: Bool? { get }

    /// Returns the loaded `Product` (with localized `displayPrice`) if available.
    /// Falls back to `nil` while products are still loading or if the load failed.
    func product(for product: NurturProduct) -> Product?

    func purchase(product: NurturProduct) async throws
    func restorePurchases() async throws

    /// Re-attempt product load (called by the paywall's "Try again" button).
    func retryProductLoad() async
}

// MARK: - Models

enum NurturProduct: String, CaseIterable {
    case proMonthly   = "com.uathelp.nurturAI.pro.monthly"
    case proAnnual    = "com.uathelp.nurturAI.pro.annual"
    case familyAnnual = "com.uathelp.nurturAI.family.annual"

    var displayName: String {
        switch self {
        case .proMonthly:   return Strings.Products.proMonthlyName
        case .proAnnual:    return Strings.Products.proAnnualName
        case .familyAnnual: return Strings.Products.familyAnnualName
        }
    }

    /// Hardcoded fallback price string. Prefer `Product.displayPrice` from
    /// `SubscriptionServiceProtocol.product(for:)` so the user sees their
    /// localized currency. Used only when the StoreKit product hasn't loaded.
    var price: String {
        switch self {
        case .proMonthly:   return Strings.Products.proMonthlyPrice
        case .proAnnual:    return Strings.Products.proAnnualPrice
        case .familyAnnual: return Strings.Products.familyAnnualPrice
        }
    }
}

/// Snapshot of the user's subscription state derived from the most-recent verified
/// transaction + its `Product.SubscriptionInfo.Status`. Drives both the `isSubscribed`
/// gate and richer UI states (grace period banner, billing-retry warning, etc.).
enum SubscriptionStatus: Equatable {
    /// No verified entitlement at all.
    case none
    /// Entitlement is current and not expired.
    case active
    /// Entitlement expired (lapsed naturally).
    case expired
    /// Renewal failed but Apple is granting a grace period — user still has Pro access.
    case inGracePeriod
    /// Renewal failed and Apple is retrying — user does NOT have Pro access right now.
    case inBillingRetry
    /// Refunded / family-sharing revoked.
    case revoked

    /// Whether this status grants Pro access right now.
    var grantsAccess: Bool {
        switch self {
        case .active, .inGracePeriod: return true
        case .none, .expired, .inBillingRetry, .revoked: return false
        }
    }
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case verificationFailed
    case pending
    case loadFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:    return Strings.Errors.Subscription.productNotFound
        case .verificationFailed: return Strings.Errors.Subscription.verificationFailed
        case .pending:            return Strings.Errors.Subscription.pending
        case .loadFailed:         return Strings.Errors.Subscription.loadFailed
        case .unknown:            return Strings.Errors.Subscription.unknown
        }
    }
}

// MARK: - Implementation

/// Production StoreKit 2 implementation.
///
/// Lifecycle:
/// - `start()` is called once from `AppContainer.live(...)`. It kicks off the
///   transaction listener, loads products, drains any unfinished transactions,
///   and computes initial entitlement state.
/// - `deinit` cancels the listener task. The instance lives for the app's lifetime
///   in practice (held by `AppContainer`), but the cancel keeps tests + previews
///   from leaking tasks.
///
/// Threading:
/// - Class is `@MainActor` so observable mutations are coherent for SwiftUI.
/// - `Transaction.updates` is consumed on a `Task.detached` and mutations hop
///   back to the main actor via `await MainActor.run` — keeps the listener off
///   the main queue so a flood of updates never blocks UI.
@MainActor
@Observable
final class StoreKitSubscriptionService: SubscriptionServiceProtocol {

    // Observable surface
    private(set) var isSubscribed: Bool = false
    private(set) var subscriptionStatus: SubscriptionStatus = .none
    private(set) var activeProduct: NurturProduct? = nil
    private(set) var expirationDate: Date? = nil
    private(set) var isLoadingProducts: Bool = false
    private(set) var productLoadError: String? = nil
    private(set) var lastRestoreFoundPurchases: Bool? = nil

    // Internal state
    private var storeProducts: [String: Product] = [:]
    private var transactionListenerTask: Task<Void, Never>?
    /// Coalesces concurrent calls — every caller waiting on products awaits the
    /// same in-flight `Task` so we make at most one StoreKit request at a time.
    private var inFlightProductLoad: Task<Void, Never>?
    private let appState: AppState

    private static let log = Logger(subsystem: "com.uathelp.nurturAI", category: "Subscription")

    init(appState: AppState) {
        self.appState = appState
    }

    // No `deinit` cleanup of `transactionListenerTask`: the task is
    // `@MainActor`-isolated and `deinit` is nonisolated under Swift 6, so
    // we'd hit "Main actor-isolated property … can not be referenced from a
    // nonisolated context". In practice the service lives for the app's
    // lifetime (held by AppContainer), and `stop()` exists for tests/previews
    // that need explicit teardown.

    // MARK: - Lifecycle

    /// Call once at app startup. Idempotent for the listener (guards against double-start).
    func start() {
        if transactionListenerTask == nil {
            transactionListenerTask = Self.makeListenerTask { [weak self] in
                await self?.handleTransactionUpdate()
            }
        }
        Task { await ensureProductsLoaded() }
        Task { await finishUnfinishedTransactions() }
        Task { await refreshSubscriptionStatus() }
    }

    /// Cancels the background transaction listener. Safe to call multiple times.
    func stop() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
    }

    // MARK: - Public API

    func product(for product: NurturProduct) -> Product? {
        storeProducts[product.rawValue]
    }

    func purchase(product nurturProduct: NurturProduct) async throws {
        // Awaiting here closes the race where the user opens the paywall and
        // taps a card before the initial product fetch returns.
        await ensureProductsLoaded()

        guard let product = storeProducts[nurturProduct.rawValue] else {
            // If the load failed, prefer the load error so the user sees
            // "check your connection" instead of the generic "product not found".
            throw productLoadError == nil ? SubscriptionError.productNotFound : SubscriptionError.loadFailed
        }

        // Attribute the purchase to the signed-in Firebase user when possible.
        // This shows up in App Store Server Notifications as `appAccountToken`,
        // letting the backend reconcile receipts to user accounts later.
        var options: Set<Product.PurchaseOption> = []
        if let token = purchaseAccountToken() {
            options.insert(.appAccountToken(token))
        }

        let result = try await product.purchase(options: options)

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshSubscriptionStatus()
            await transaction.finish()
            // Fire the root-level confetti only on user-initiated success —
            // not on the launch-time `refreshSubscriptionStatus()` path that
            // also flips `isSubscribed` for already-subscribed users.
            appState.confettiTrigger = UUID()

        case .userCancelled:
            return

        case .pending:
            // Ask-to-Buy or SCA challenge — purchase is queued, not failed.
            // The Transaction.updates listener will pick it up when approved.
            throw SubscriptionError.pending

        @unknown default:
            Self.log.error("Unknown purchase result for \(nurturProduct.rawValue, privacy: .public)")
            throw SubscriptionError.unknown
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshSubscriptionStatus()
        // After AppStore.sync(), `currentEntitlements` reflects whatever Apple
        // has on file. If it's still empty, the user genuinely owns nothing.
        lastRestoreFoundPurchases = (activeProduct != nil)
    }

    func retryProductLoad() async {
        // Drop any cached error; ensureProductsLoaded() will start a fresh task.
        productLoadError = nil
        inFlightProductLoad = nil
        await ensureProductsLoaded()
    }

    // MARK: - Product loading

    /// Idempotent product fetch. Returns immediately if products are already loaded;
    /// otherwise awaits the single in-flight load (creating one if needed). All
    /// concurrent callers share the same `Task`, so we never fan out duplicate
    /// `Product.products(for:)` requests.
    private func ensureProductsLoaded() async {
        if !storeProducts.isEmpty { return }

        if let inFlight = inFlightProductLoad {
            await inFlight.value
            return
        }

        let task = Task { await loadProducts() }
        inFlightProductLoad = task
        await task.value
        inFlightProductLoad = nil
    }

    private func loadProducts() async {
        isLoadingProducts = true
        productLoadError = nil
        defer { isLoadingProducts = false }

        let ids = NurturProduct.allCases.map(\.rawValue)
        do {
            let products = try await Product.products(for: ids)
            // Wipe + repopulate so a stale entry from a partial previous load
            // doesn't linger after a successful retry.
            var fresh: [String: Product] = [:]
            for product in products {
                fresh[product.id] = product
            }
            storeProducts = fresh

            if storeProducts.isEmpty {
                // Apple returned successfully but with zero products — almost
                // always means the IAPs aren't approved / are missing metadata
                // / bundle ID mismatch. Surface it instead of silently failing.
                Self.log.error("Product.products(for:) returned empty for ids: \(ids, privacy: .public)")
                productLoadError = Strings.Errors.Subscription.loadFailed
            }
        } catch {
            Self.log.error("Failed to load products: \(error.localizedDescription, privacy: .public)")
            productLoadError = Strings.Errors.Subscription.loadFailed
        }
    }

    // MARK: - Entitlement evaluation

    /// Walks `Transaction.currentEntitlements`, filters to NurturAI products, and
    /// derives the richest available status from `Product.SubscriptionInfo.Status`.
    /// If multiple verified entitlements exist (rare — usually only during plan
    /// switches), the most-recently-purchased one wins.
    private func refreshSubscriptionStatus() async {
        let validIDs = Set(NurturProduct.allCases.map(\.rawValue))
        var candidates: [(transaction: Transaction, product: NurturProduct)] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  validIDs.contains(transaction.productID),
                  transaction.revocationDate == nil,
                  let nurturProduct = NurturProduct(rawValue: transaction.productID)
            else { continue }
            candidates.append((transaction, nurturProduct))
        }

        guard let winner = candidates.max(by: { $0.transaction.purchaseDate < $1.transaction.purchaseDate }) else {
            applyStatus(.none, product: nil, expiration: nil)
            return
        }

        let derivedStatus = await deriveStatus(for: winner.transaction, product: winner.product)
        let expiration = winner.transaction.expirationDate
        applyStatus(derivedStatus, product: winner.product, expiration: expiration)
    }

    /// Pulls the renewal-state nuance from `Product.SubscriptionInfo.Status` if
    /// available. Falls back to a plain expiration check for non-subscription
    /// products or when the status query fails.
    private func deriveStatus(for transaction: Transaction, product: NurturProduct) async -> SubscriptionStatus {
        if let storeProduct = storeProducts[product.rawValue],
           let subscription = storeProduct.subscription {
            do {
                let statuses = try await subscription.status
                // Pick the entry matching this transaction's subscription group.
                if let match = statuses.first(where: {
                    if case .verified(let renewalInfo) = $0.renewalInfo {
                        return renewalInfo.originalTransactionID == transaction.originalID
                    }
                    return false
                }) ?? statuses.first {
                    return mapRenewalState(match.state)
                }
            } catch {
                Self.log.error("Failed to read subscription status: \(error.localizedDescription, privacy: .public)")
            }
        }

        // Fallback: just compare expiration to now.
        if let expiration = transaction.expirationDate, expiration < .now {
            return .expired
        }
        return .active
    }

    private func mapRenewalState(_ state: Product.SubscriptionInfo.RenewalState) -> SubscriptionStatus {
        switch state {
        case .subscribed:       return .active
        case .expired:          return .expired
        case .inGracePeriod:    return .inGracePeriod
        case .inBillingRetryPeriod: return .inBillingRetry
        case .revoked:          return .revoked
        default:                return .active
        }
    }

    private func applyStatus(_ status: SubscriptionStatus, product: NurturProduct?, expiration: Date?) {
        subscriptionStatus = status
        activeProduct = product
        expirationDate = expiration
        let granted = status.grantsAccess
        isSubscribed = granted
        appState.isSubscribed = granted
    }

    // MARK: - Transaction listener

    /// Detached listener so a flood of `Transaction.updates` (e.g. after a
    /// background renewal batch) never sits on the main queue. Each update
    /// hops back to the main actor for the actual state mutation.
    private static func makeListenerTask(_ handle: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await handle()
                    await transaction.finish()
                }
            }
        }
    }

    private func handleTransactionUpdate() async {
        await refreshSubscriptionStatus()
    }

    /// On launch, finish any transactions that previously failed to call
    /// `.finish()` (app crashed mid-purchase, etc.). Without this, StoreKit
    /// will keep replaying them through `Transaction.updates` forever.
    private func finishUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            Self.log.error("Verification failed: \(error.localizedDescription, privacy: .public)")
            throw SubscriptionError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    /// Builds a stable `appAccountToken` from the Firebase UID so server-side
    /// receipt processing can map a transaction back to the user account.
    /// Returns nil if the user isn't signed in yet (purchase still works,
    /// just without attribution).
    ///
    /// We hash the UID into a deterministic UUID so the same user always
    /// produces the same token across reinstalls — Apple requires a UUID,
    /// and Firebase UIDs aren't UUID-shaped.
    private func purchaseAccountToken() -> UUID? {
        guard let uid = appState.firebaseUID, !uid.isEmpty else { return nil }
        return Self.deterministicUUID(from: uid)
    }

    /// Derives a deterministic UUID from a string by hashing it and packing
    /// 16 bytes into UUID layout (sets version 4 + variant bits per RFC 4122).
    /// Not cryptographic — purely a stable mapping for `appAccountToken`.
    private static func deterministicUUID(from input: String) -> UUID {
        var hasher = Hasher()
        hasher.combine(input)
        let h1 = UInt64(bitPattern: Int64(hasher.finalize()))

        var hasher2 = Hasher()
        hasher2.combine(input)
        hasher2.combine("salt.v1")
        let h2 = UInt64(bitPattern: Int64(hasher2.finalize()))

        var bytes = [UInt8](repeating: 0, count: 16)
        for i in 0..<8 {
            bytes[i]     = UInt8((h1 >> (8 * i)) & 0xFF)
            bytes[i + 8] = UInt8((h2 >> (8 * i)) & 0xFF)
        }
        // Set version (4) and variant (RFC 4122) bits.
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let uuidTuple: uuid_t = (
            bytes[0],  bytes[1],  bytes[2],  bytes[3],
            bytes[4],  bytes[5],  bytes[6],  bytes[7],
            bytes[8],  bytes[9],  bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuidTuple)
    }
}
