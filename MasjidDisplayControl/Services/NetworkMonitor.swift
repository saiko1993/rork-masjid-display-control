import Foundation
import Network

@Observable
@MainActor
class NetworkMonitor {
    var isConnected: Bool = true
    var isWiFi: Bool = false
    var interfaceType: String = "unknown"

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")

    func start() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.isWiFi = path.usesInterfaceType(.wifi)
                if path.usesInterfaceType(.wifi) {
                    self.interfaceType = "WiFi"
                } else if path.usesInterfaceType(.cellular) {
                    self.interfaceType = "Cellular"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.interfaceType = "Ethernet"
                } else {
                    self.interfaceType = "Other"
                }
            }
        }
        monitor?.start(queue: queue)
    }

    func stop() {
        monitor?.cancel()
        monitor = nil
    }
}
