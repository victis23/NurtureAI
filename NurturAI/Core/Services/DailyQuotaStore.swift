import Foundation
import Security

/// Keychain-backed counter store for the free-tier daily AI query quota.
///
/// Why Keychain (not UserDefaults): Keychain items survive app uninstall on
/// iOS, which closes the "delete-and-reinstall to reset the limit" abuse
/// vector. The previous UserDefaults implementation was wiped on every
/// reinstall.
///
/// Scope:
/// - One value per day-key (e.g. "queryCount_2026-04-24"), stored under a
///   shared service identifier so all per-day entries are easy to enumerate
///   if we ever need to migrate or purge.
/// - Synchronous API. Keychain calls are O(microseconds) for small payloads
///   and AssistViewModel reads the count once on init / after each save.
/// - Accessibility: `kSecAttrAccessibleAfterFirstUnlock` — readable after
///   the user unlocks the device once per boot, survives reboots, but not
///   readable before first unlock. AssistView is gated behind sign-in so
///   this never matters in practice.
///
/// Threading: pure value-in / value-out. No shared mutable state. Safe to
/// call from any actor.
struct DailyQuotaStore {

    // MARK: - Configuration

    /// Bundle-scoped service identifier so other apps signed by the same
    /// developer can't read or collide with our entries.
    static let service = "com.uathelp.nurturAI.dailyQuota"

    // MARK: - Public API

    /// Reads the count for a given day-key. Returns 0 if no entry exists.
    /// Logs and returns 0 on Keychain errors — failing closed (treating
    /// the user as having 0 queries) would be wrong; failing open (0 used)
    /// matches UserDefaults behaviour and is acceptable since the worst
    /// case is the user gets one extra query.
    func count(forKey key: String) -> Int {
        var query: [String: Any] = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            // errSecItemNotFound is the normal "no entry yet" case — silent.
            return 0
        }
        guard let data = item as? Data,
              let str  = String(data: data, encoding: .utf8),
              let value = Int(str) else {
            return 0
        }
        return value
    }

    /// Writes (or updates) the count for a given day-key. No-ops on
    /// Keychain errors — see `count(forKey:)` for failure-mode rationale.
    func setCount(_ count: Int, forKey key: String) {
        let payload = String(count).data(using: .utf8) ?? Data()
        let attrs: [String: Any] = [
            kSecValueData as String: payload,
        ]

        // Try to update first; if the entry doesn't exist yet, fall through
        // to add. This pattern avoids a separate "exists?" round-trip.
        let updateStatus = SecItemUpdate(baseQuery(forKey: key) as CFDictionary,
                                         attrs as CFDictionary)
        if updateStatus == errSecSuccess { return }

        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery(forKey: key)
            addQuery[kSecValueData as String] = payload
            addQuery[kSecAttrAccessible as String] =
                kSecAttrAccessibleAfterFirstUnlock
            _ = SecItemAdd(addQuery as CFDictionary, nil)
        }
        // Any other status is silently dropped — see rationale above.
    }

    /// Removes a single entry. Currently unused at runtime; included for
    /// tests and for future "reset my account" flows.
    func remove(forKey key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }

    // MARK: - Internals

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
        ]
    }
}
