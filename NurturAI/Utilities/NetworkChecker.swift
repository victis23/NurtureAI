import Foundation
import Network

/// One-shot network reachability check. Used at decision points (e.g. before
/// the onboarding preview screen) to choose between an online and offline path.
///
/// Implementation note: `NWPathMonitor` delivers its first `pathUpdateHandler`
/// callback almost immediately after `start()` — the brief sleep below is just
/// a window for that callback to populate `currentPath`, then we read it and
/// cancel. Conservatively returns `false` if the monitor reports anything
/// other than `.satisfied`.
enum NetworkChecker {

    static func isOnline() async -> Bool {
        let monitor = NWPathMonitor()
        monitor.start(queue: DispatchQueue.global(qos: .userInitiated))
        defer { monitor.cancel() }

        try? await Task.sleep(for: .milliseconds(150))

        return monitor.currentPath.status == .satisfied
    }
}
