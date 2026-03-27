import Foundation
import WatchConnectivity

@Observable
@MainActor
class WatchSessionManager: NSObject {
    var watchState: WatchState = .empty
    var isReachable: Bool = false
    var lastReceived: Date? = nil

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        loadCachedState()
    }

    func requestUpdate() {
        guard let session, session.isReachable else { return }
        session.sendMessage(["request": "update"], replyHandler: nil)
    }

    private func loadCachedState() {
        guard let data = UserDefaults.standard.data(forKey: "cachedWatchState"),
              let state = try? JSONDecoder().decode(WatchState.self, from: data) else { return }
        watchState = state
        lastReceived = state.updatedAt
    }

    private func cacheState(_ state: WatchState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: "cachedWatchState")
        }
    }

    private func processMessage(_ message: [String: Any]) {
        guard let data = message["watchState"] as? Data,
              let state = try? JSONDecoder().decode(WatchState.self, from: data) else { return }
        Task { @MainActor in
            self.watchState = state
            self.lastReceived = Date()
            self.cacheState(state)
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                self.requestUpdate()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.processMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.processMessage(message)
        }
        replyHandler(["received": true])
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.processMessage(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            self.processMessage(userInfo)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            if session.isReachable {
                self.requestUpdate()
            }
        }
    }
}
