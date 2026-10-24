import Foundation
import Network
import Observation

/// Whether the network is there (P4-11). When it comes back, the app sends
/// what queued up offline and reloads.
@Observable
final class Connectivity {
    private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "Connectivity"))
    }
}
