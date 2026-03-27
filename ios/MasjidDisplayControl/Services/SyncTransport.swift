import Foundation

nonisolated enum TransportError: Error, Sendable {
    case notConnected
    case invalidURL
    case encodingFailed
    case httpError(Int)
    case networkError(String)
    case bleNotReady
    case bleWriteFailed
    case timeout
    case cancelled
}

protocol SyncTransport: Sendable {
    var transportName: String { get }
    func sendThemePack(data: Data, config: TransportConfig) async throws
    func sendLightSync(data: Data, config: TransportConfig) async throws
    func testConnection(config: TransportConfig) async throws -> String
}

nonisolated struct TransportConfig: Sendable {
    let baseUrl: String
    let apiKey: String
    let useHMAC: Bool
    let hmacSecret: String
    let bleDeviceName: String

    init(from target: PushTarget) {
        self.baseUrl = target.baseUrl
        self.apiKey = target.apiKey
        self.useHMAC = target.useHMAC
        self.hmacSecret = target.hmacSecret
        self.bleDeviceName = target.bleDeviceName
    }
}
