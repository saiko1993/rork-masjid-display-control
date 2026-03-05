import Foundation
import Network
import UIKit

nonisolated enum SyncConnectionState: String, Sendable {
    case disconnected
    case searching
    case connected
    case syncing
    case error
}

@Observable
@MainActor
class ConnectionManager {
    var connectionState: SyncConnectionState = .disconnected
    var lastSyncDate: Date? = nil
    var lastError: String? = nil
    var discoveredHost: String? = nil
    var isAutoSyncEnabled: Bool = true
    var isPaired: Bool = false
    var pendingCount: Int = 0
    var lastThemePackDate: Date? = nil
    var lastLightSyncDate: Date? = nil
    var networkAvailable: Bool = true
    var consecutiveFailures: Int = 0
    var lastPingDate: Date? = nil
    var serverResponseTimeMs: Int = 0

    private var debounceTask: Task<Void, Never>? = nil
    private var retryTask: Task<Void, Never>? = nil
    private var pendingChanges: [PendingChange] = []
    private let restTransport = RestTransport()
    private var monitorTask: Task<Void, Never>? = nil
    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "cm.network")
    private var wasDisconnectedByNetwork: Bool = false

    struct PendingChange: Sendable {
        let type: PushType
        let data: Data
        let config: TransportConfig
    }

    init() {
        loadPairingState()
        loadPendingQueue()
    }

    func startMonitoring(store: AppStore) {
        startNetworkMonitor(store: store)
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if self.networkAvailable {
                    if self.isAutoSyncEnabled {
                        if self.connectionState == .connected {
                            await self.pingServer(store: store)
                            if self.connectionState == .connected && !self.pendingChanges.isEmpty {
                                await self.flushPendingChanges(store: store, bleManager: nil)
                            }
                        } else if self.connectionState == .disconnected || self.connectionState == .error {
                            await self.tryConnect(store: store)
                        }
                    } else {
                        if self.connectionState == .disconnected || self.connectionState == .error {
                            await self.tryConnect(store: store)
                        }
                        if self.connectionState == .connected && !self.pendingChanges.isEmpty {
                            await self.flushPendingChanges(store: store, bleManager: nil)
                        }
                    }
                }
                let interval: Double
                if self.isAutoSyncEnabled && self.connectionState == .connected {
                    interval = 15
                } else if self.connectionState == .connected {
                    interval = 45
                } else {
                    interval = min(Double(max(1, self.consecutiveFailures)) * 10, 60)
                }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
        networkMonitor?.cancel()
        networkMonitor = nil
    }

    private func startNetworkMonitor(store: AppStore) {
        networkMonitor?.cancel()
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasAvailable = self.networkAvailable
                self.networkAvailable = path.status == .satisfied
                if !wasAvailable && self.networkAvailable {
                    self.wasDisconnectedByNetwork = false
                    self.consecutiveFailures = 0
                    await self.tryConnect(store: store)
                } else if wasAvailable && !self.networkAvailable {
                    self.wasDisconnectedByNetwork = true
                    self.connectionState = .disconnected
                    self.lastError = "Network unavailable"
                }
            }
        }
        networkMonitor?.start(queue: networkQueue)
    }

    private func pingServer(store: AppStore) async {
        let config = TransportConfig(from: store.pushTarget)
        guard !config.baseUrl.isEmpty else { return }
        let urlString = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/info"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        request.httpMethod = "GET"
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw TransportError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            let elapsed = Date().timeIntervalSince(start)
            serverResponseTimeMs = Int(elapsed * 1000)
            lastPingDate = Date()
            if connectionState != .connected && connectionState != .syncing {
                connectionState = .connected
            }
            consecutiveFailures = 0
            lastError = nil
        } catch {
            consecutiveFailures += 1
            if consecutiveFailures >= 3 {
                connectionState = .error
                lastError = "Lost connection to server"
            }
        }
    }

    func reconnect(store: AppStore) async {
        connectionState = .searching
        lastError = nil

        let config = TransportConfig(from: store.pushTarget)
        guard !config.baseUrl.isEmpty else {
            connectionState = .error
            lastError = "No server URL configured"
            return
        }

        do {
            _ = try await restTransport.testConnection(config: config)
            connectionState = .connected
            discoveredHost = config.baseUrl
            lastError = nil
            consecutiveFailures = 0
            lastPingDate = Date()

            SecureStorageService.savePairingState(
                isPaired: isPaired,
                deviceId: nil,
                lastServerIP: config.baseUrl
            )

            if !pendingChanges.isEmpty {
                await flushPendingChanges(store: store, bleManager: nil)
            }
        } catch {
            consecutiveFailures += 1
            connectionState = .error
            lastError = "Cannot reach \(config.baseUrl)"
        }
    }

    func tryConnect(store: AppStore) async {
        let config = TransportConfig(from: store.pushTarget)
        guard !config.baseUrl.isEmpty else { return }
        guard networkAvailable else {
            connectionState = .disconnected
            lastError = "No network"
            return
        }

        if connectionState != .searching {
            connectionState = .searching
        }
        lastError = nil

        do {
            let start = Date()
            _ = try await restTransport.testConnection(config: config)
            let elapsed = Date().timeIntervalSince(start)
            serverResponseTimeMs = Int(elapsed * 1000)
            connectionState = .connected
            discoveredHost = config.baseUrl
            lastError = nil
            consecutiveFailures = 0
            lastPingDate = Date()
        } catch {
            consecutiveFailures += 1
            connectionState = .error
            lastError = "Cannot reach server"
        }
    }

    func pairDevice(store: AppStore, bleManager: BLEManager?) async -> Bool {
        if connectionState != .connected {
            await reconnect(store: store)
        }
        guard connectionState == .connected else { return false }

        connectionState = .syncing

        let themePayload = PayloadBuilder.buildThemePack(from: store)
        guard let themeData = PayloadBuilder.encode(themePayload) else {
            connectionState = .error
            lastError = "Failed to encode theme"
            return false
        }

        let config = TransportConfig(from: store.pushTarget)
        do {
            try await restTransport.sendThemePack(data: themeData, config: config)
            lastThemePackDate = Date()
        } catch {
            connectionState = .error
            lastError = "Theme pack failed: \(error.localizedDescription)"
            return false
        }

        let syncPayload = PayloadBuilder.buildLightSync(from: store)
        guard let syncData = PayloadBuilder.encode(syncPayload) else {
            connectionState = .error
            lastError = "Failed to encode sync"
            return false
        }

        do {
            try await restTransport.sendLightSync(data: syncData, config: config)
            lastLightSyncDate = Date()
        } catch {
            connectionState = .error
            lastError = "Light sync failed: \(error.localizedDescription)"
            return false
        }

        connectionState = .connected
        lastSyncDate = Date()
        lastError = nil
        isPaired = true
        savePairingState()

        SecureStorageService.saveCredentials(
            baseUrl: store.pushTarget.baseUrl,
            apiKey: store.pushTarget.apiKey,
            hmacSecret: store.pushTarget.hmacSecret
        )
        SecureStorageService.savePairingState(
            isPaired: true,
            deviceId: discoveredHost,
            lastServerIP: config.baseUrl
        )

        return true
    }

    func scheduleLightSync(store: AppStore, bleManager: BLEManager) {
        guard isAutoSyncEnabled else { return }
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await sendLightSync(store: store, bleManager: bleManager)
        }
    }

    func sendLightSync(store: AppStore, bleManager: BLEManager?) async {
        if connectionState != .connected && connectionState != .syncing {
            await tryConnect(store: store)
            if connectionState != .connected {
                queueChange(store: store, type: .lightSync)
                return
            }
        }

        let payload = PayloadBuilder.buildLightSync(from: store)
        guard let data = PayloadBuilder.encode(payload) else { return }

        let config = TransportConfig(from: store.pushTarget)
        connectionState = .syncing

        do {
            try await restTransport.sendLightSync(data: data, config: config)
            connectionState = .connected
            lastSyncDate = Date()
            lastLightSyncDate = Date()
            lastError = nil
        } catch {
            connectionState = .error
            lastError = error.localizedDescription
            queueChange(store: store, type: .lightSync)
            scheduleRetry(store: store, bleManager: bleManager)
        }
    }

    func sendThemePack(store: AppStore, bleManager: BLEManager?) async {
        if connectionState != .connected && connectionState != .syncing {
            await tryConnect(store: store)
            if connectionState != .connected { return }
        }

        let payload = PayloadBuilder.buildThemePack(from: store)
        guard let data = PayloadBuilder.encode(payload) else { return }

        let config = TransportConfig(from: store.pushTarget)
        connectionState = .syncing

        do {
            try await restTransport.sendThemePack(data: data, config: config)
            connectionState = .connected
            lastSyncDate = Date()
            lastThemePackDate = Date()
            lastError = nil
        } catch {
            connectionState = .error
            lastError = error.localizedDescription
        }
    }

    func sendTickerMessage(message: String, store: AppStore) async {
        let config = TransportConfig(from: store.pushTarget)
        let body: [String: String] = ["message": message]
        guard let data = try? JSONEncoder().encode(body) else { return }

        do {
            try await restTransport.sendCustom(path: "/v1/ticker", data: data, config: config)
            lastSyncDate = Date()
        } catch {
            lastError = "Failed to send ticker: \(error.localizedDescription)"
        }
    }

    func uploadBackgroundImage(imageData: Data, filename: String, store: AppStore) async -> String? {
        let config = TransportConfig(from: store.pushTarget)
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let urlString = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/upload-background"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 30
        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
            if let json = try? JSONDecoder().decode(UploadResponse.self, from: responseData) {
                return json.url
            }
            return nil
        } catch {
            lastError = "Upload failed: \(error.localizedDescription)"
            return nil
        }
    }

    func flushPendingChanges(store: AppStore, bleManager: BLEManager?) async {
        guard connectionState == .connected, !pendingChanges.isEmpty else { return }
        let changes = pendingChanges
        pendingChanges.removeAll()
        pendingCount = 0
        savePendingQueue()

        for change in changes {
            connectionState = .syncing
            do {
                if change.type == .themePack {
                    try await restTransport.sendThemePack(data: change.data, config: change.config)
                    lastThemePackDate = Date()
                } else {
                    try await restTransport.sendLightSync(data: change.data, config: change.config)
                    lastLightSyncDate = Date()
                }
                lastSyncDate = Date()
            } catch {
                lastError = error.localizedDescription
            }
        }
        connectionState = .connected
    }

    func runDiagnostics(store: AppStore) async -> [DiagnosticResult] {
        let config = TransportConfig(from: store.pushTarget)
        let base = config.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let endpoints: [(String, String, String)] = [
            ("GET /v1/info", base + "/v1/info", "GET"),
            ("GET /v1/state", base + "/v1/state", "GET"),
            ("GET /display", base + "/display", "GET"),
            ("POST /v1/theme", base + "/v1/theme", "POST"),
            ("POST /v1/sync", base + "/v1/sync", "POST"),
            ("POST /v1/upload-background", base + "/v1/upload-background", "POST"),
            ("POST /v1/ticker", base + "/v1/ticker", "POST"),
            ("POST /v1/audio", base + "/v1/audio", "POST"),
            ("POST /v1/power", base + "/v1/power", "POST"),
            ("POST /v1/ramadan", base + "/v1/ramadan", "POST"),
            ("POST /v1/quran-program", base + "/v1/quran-program", "POST"),
        ]

        var results: [DiagnosticResult] = []

        for (name, urlString, method) in endpoints {
            guard let url = URL(string: urlString) else {
                results.append(DiagnosticResult(name: name, statusCode: 0, responseTime: 0, error: "Invalid URL"))
                continue
            }

            var request = URLRequest(url: url)
            request.httpMethod = method
            request.timeoutInterval = 8
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

            if method == "POST" {
                if urlString.hasSuffix("/v1/theme") {
                    let themePayload = PayloadBuilder.buildThemePack(from: store)
                    guard let themeData = PayloadBuilder.encode(themePayload) else {
                        results.append(DiagnosticResult(name: name, statusCode: 0, responseTime: 0, error: "Failed to encode theme payload"))
                        continue
                    }
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = themeData
                } else if urlString.hasSuffix("/v1/upload-background") {
                    let boundary = UUID().uuidString
                    var body = Data()
                    let testImageData = makeMinimalJPEGData()
                    body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
                    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"test.jpg\"\r\n".data(using: .utf8) ?? Data())
                    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8) ?? Data())
                    body.append(testImageData)
                    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())
                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    request.httpBody = body
                } else {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = "{}".data(using: .utf8)
                }
            }

            let start = Date()
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let elapsed = Date().timeIntervalSince(start)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                results.append(DiagnosticResult(name: name, statusCode: code, responseTime: elapsed, error: nil))
            } catch {
                let elapsed = Date().timeIntervalSince(start)
                results.append(DiagnosticResult(name: name, statusCode: 0, responseTime: elapsed, error: error.localizedDescription))
            }
        }

        return results
    }

    private func makeMinimalJPEGData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return image.jpegData(compressionQuality: 0.1) ?? Data()
    }

    func generateDebugReport(store: AppStore, results: [DiagnosticResult]) -> String {
        var report = "=== Masjid Controller Debug Report ===\n"
        report += "Date: \(Date())\n"
        report += "Server: \(store.pushTarget.baseUrl)\n"
        report += "Transport: \(store.pushTarget.transportMode.displayName)\n"
        report += "Connection: \(connectionState.rawValue)\n"
        report += "Paired: \(isPaired)\n"
        report += "Auto-Sync: \(isAutoSyncEnabled)\n"
        report += "Network: \(networkAvailable ? "Available" : "Unavailable")\n"
        report += "Pending Queue: \(pendingCount)\n"
        if let date = lastSyncDate {
            report += "Last Sync: \(date)\n"
        }
        if let error = lastError {
            report += "Last Error: \(error)\n"
        }
        report += "Ping: \(serverResponseTimeMs)ms\n"
        report += "\n--- API Diagnostics ---\n"
        for r in results {
            let status = r.isSuccess ? "OK" : "FAIL"
            report += "[\(status)] \(r.name) — HTTP \(r.statusCode) — \(Int(r.responseTime * 1000))ms"
            if let err = r.error { report += " — \(err)" }
            report += "\n"
        }
        report += "\n--- Theme ---\n"
        report += "Active: \(store.selectedTheme.displayName)\n"
        report += "Schedule: \(store.prayerSchedule.count) prayers\n"
        report += "Location: \(store.location.cityName)\n"
        report += "Time Format: \(store.timeFormat.displayName)\n"
        report += "Large Mode: \(store.largeMode)\n"
        report += "\n--- Server Logs ---\n"
        report += "journalctl -u masjid-api -f\n"
        return report
    }

    private func queueChange(store: AppStore, type: PushType) {
        let config = TransportConfig(from: store.pushTarget)
        let data: Data?
        if type == .themePack {
            data = PayloadBuilder.encode(PayloadBuilder.buildThemePack(from: store))
        } else {
            data = PayloadBuilder.encode(PayloadBuilder.buildLightSync(from: store))
        }
        guard let data else { return }
        pendingChanges.removeAll { $0.type == type }
        pendingChanges.append(PendingChange(type: type, data: data, config: config))
        pendingCount = pendingChanges.count
        savePendingQueue()
    }

    private func scheduleRetry(store: AppStore, bleManager: BLEManager?) {
        retryTask?.cancel()
        retryTask = Task {
            var delay: Double = 2
            for _ in 0..<5 {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                await tryConnect(store: store)
                if connectionState == .connected {
                    await flushPendingChanges(store: store, bleManager: bleManager)
                    return
                }
                delay = min(delay * 2, 30)
            }
        }
    }

    private func savePairingState() {
        UserDefaults.standard.set(isPaired, forKey: "cm_isPaired")
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "cm_lastSyncDate")
        }
        SecureStorageService.savePairingState(isPaired: isPaired, deviceId: discoveredHost, lastServerIP: discoveredHost)
    }

    private func loadPairingState() {
        isPaired = UserDefaults.standard.bool(forKey: "cm_isPaired")
        lastSyncDate = UserDefaults.standard.object(forKey: "cm_lastSyncDate") as? Date
        let secure = SecureStorageService.loadPairingState()
        if secure.isPaired { isPaired = true }
    }

    private func savePendingQueue() {
        let entries = pendingChanges.map {
            PersistedPendingChange(type: $0.type, data: $0.data, timestamp: Date())
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "cm_pendingQueue")
        }
    }

    private func loadPendingQueue() {
        guard let data = UserDefaults.standard.data(forKey: "cm_pendingQueue"),
              let entries = try? JSONDecoder().decode([PersistedPendingChange].self, from: data),
              !entries.isEmpty else { return }
        let config = TransportConfig(from: PushTarget.default)
        pendingChanges = entries.map { PendingChange(type: $0.type, data: $0.data, config: config) }
        pendingCount = pendingChanges.count
    }

}

nonisolated struct PersistedPendingChange: Codable, Sendable {
    let type: PushType
    let data: Data
    let timestamp: Date
}

nonisolated struct UploadResponse: Codable, Sendable {
    let url: String
}

nonisolated struct DiagnosticResult: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let statusCode: Int
    let responseTime: TimeInterval
    let error: String?

    var isSuccess: Bool {
        error == nil && (200...299).contains(statusCode)
    }

    var isNotImplemented: Bool {
        statusCode == 404
    }

    var statusLabel: String {
        if error != nil && statusCode == 0 { return "Unreachable" }
        if statusCode == 404 { return "Not implemented" }
        if (200...299).contains(statusCode) { return "Pass" }
        if (400...499).contains(statusCode) { return "Client error" }
        if statusCode >= 500 { return "Server error" }
        return "Unknown"
    }
}
