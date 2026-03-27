import Foundation

@Observable
@MainActor
class PushService {
    var pushHistory: [PushHistoryEntry] = []
    var isSending: Bool = false
    var retryCount: Int = 0
    var lastThemePackSent: Date? = nil
    var queueLength: Int = 0

    private let maxRetries = 3
    private let historyKey = "pushHistory"
    private let restTransport = RestTransport()

    var lastSuccess: PushHistoryEntry? {
        pushHistory.first { $0.status == .success }
    }

    var lastEntry: PushHistoryEntry? {
        pushHistory.first
    }

    init() {
        loadHistory()
    }

    func resolveTransport(mode: TransportMode, bleManager: BLEManager) -> any SyncTransport {
        switch mode {
        case .wifi:
            return restTransport
        case .bluetooth:
            return BLESyncTransport(bleManager: bleManager)
        case .auto:
            if bleManager.isReady {
                return BLESyncTransport(bleManager: bleManager)
            }
            return restTransport
        }
    }

    func sendThemePack(store: AppStore, bleManager: BLEManager) async {
        isSending = true
        retryCount = 0
        queueLength = 1

        let payload = PayloadBuilder.buildThemePack(from: store)
        guard let data = PayloadBuilder.encode(payload) else {
            addEntry(.failure, message: "Failed to encode theme pack", type: .themePack, transport: "—")
            isSending = false
            queueLength = 0
            return
        }

        let transport = resolveTransport(mode: store.pushTarget.transportMode, bleManager: bleManager)
        let config = TransportConfig(from: store.pushTarget)

        let success = await sendWithRetry(transport: transport, config: config, data: data, type: .themePack)

        if success {
            lastThemePackSent = Date()
        }
        isSending = false
        queueLength = 0
    }

    func sendLightSync(store: AppStore, bleManager: BLEManager) async {
        isSending = true
        retryCount = 0
        queueLength = 1

        let payload = PayloadBuilder.buildLightSync(from: store)
        guard let data = PayloadBuilder.encode(payload) else {
            addEntry(.failure, message: "Failed to encode sync payload", type: .lightSync, transport: "—")
            isSending = false
            queueLength = 0
            return
        }

        let transport = resolveTransport(mode: store.pushTarget.transportMode, bleManager: bleManager)
        let config = TransportConfig(from: store.pushTarget)

        await sendWithRetry(transport: transport, config: config, data: data, type: .lightSync)

        isSending = false
        queueLength = 0
    }

    func testConnection(store: AppStore, bleManager: BLEManager) async -> (Bool, String) {
        let transport = resolveTransport(mode: store.pushTarget.transportMode, bleManager: bleManager)
        let config = TransportConfig(from: store.pushTarget)

        do {
            let message = try await transport.testConnection(config: config)
            addEntry(.success, message: message, type: .testConnection, transport: transport.transportName)
            return (true, message)
        } catch TransportError.bleNotReady {
            let msg = "Bluetooth not ready. Scan for devices first."
            addEntry(.failure, message: msg, type: .testConnection, transport: transport.transportName)
            return (false, msg)
        } catch TransportError.invalidURL {
            let msg = "Invalid URL"
            addEntry(.failure, message: msg, type: .testConnection, transport: transport.transportName)
            return (false, msg)
        } catch TransportError.httpError(let code) {
            let msg = "HTTP error \(code)"
            addEntry(.failure, message: msg, type: .testConnection, transport: transport.transportName)
            return (false, msg)
        } catch {
            let msg = "Connection failed: \(error.localizedDescription)"
            addEntry(.failure, message: msg, type: .testConnection, transport: transport.transportName)
            return (false, msg)
        }
    }

    @discardableResult
    private func sendWithRetry(
        transport: any SyncTransport,
        config: TransportConfig,
        data: Data,
        type: PushType
    ) async -> Bool {
        let isTheme = type == .themePack
        let name = transport.transportName

        while retryCount <= maxRetries {
            do {
                if isTheme {
                    try await transport.sendThemePack(data: data, config: config)
                } else {
                    try await transport.sendLightSync(data: data, config: config)
                }
                addEntry(.success, message: "\(type.displayName) sent via \(name)", type: type, transport: name)
                return true
            } catch {
                if retryCount < maxRetries {
                    retryCount += 1
                    let delay = pow(2.0, Double(retryCount))
                    do {
                        try await Task.sleep(for: .seconds(delay))
                    } catch {
                        addEntry(.failure, message: "Cancelled", type: type, transport: name)
                        return false
                    }
                    continue
                }
                addEntry(.failure, message: "Failed after \(maxRetries + 1) attempts: \(error.localizedDescription)", type: type, transport: name)
                return false
            }
        }
        return false
    }

    private func addEntry(_ status: PushResultStatus, message: String, type: PushType, transport: String) {
        let entry = PushHistoryEntry(status: status, message: message, pushType: type, transport: transport)
        pushHistory.insert(entry, at: 0)
        if pushHistory.count > 20 {
            pushHistory = Array(pushHistory.prefix(20))
        }
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(pushHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([PushHistoryEntry].self, from: data) else { return }
        pushHistory = history
    }
}
