import Foundation
import WatchConnectivity

@Observable
@MainActor
class WatchSyncService: NSObject {
    var isWatchReachable: Bool = false
    var isWatchPaired: Bool = false
    var lastSentDate: Date? = nil

    private var session: WCSession?
    private var pendingState: WatchStatePayload?
    private var updateThrottle: Task<Void, Never>?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendState(from store: AppStore) {
        updateThrottle?.cancel()
        updateThrottle = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSend(from: store)
        }
    }

    private func performSend(from store: AppStore) async {
        let stateInfo = store.stateInfo
        let prayers = store.prayerSchedule.map { pt -> WatchPrayerEntryPayload in
            WatchPrayerEntryPayload(
                prayerKey: pt.prayer.rawValue,
                nameEn: pt.prayer.displayName,
                nameAr: pt.prayer.displayNameAr,
                time: pt.time,
                icon: pt.prayer.iconName
            )
        }

        let payload = WatchStatePayload(
            nextPrayerKey: stateInfo.nextPrayer?.rawValue ?? "fajr",
            nextPrayerAr: stateInfo.nextPrayer?.displayNameAr ?? "",
            nextPrayerEn: stateInfo.nextPrayer?.displayName ?? "",
            countdownSeconds: stateInfo.countdownSeconds,
            phase: stateInfo.phase.rawValue,
            city: store.location.cityName,
            prayers: prayers,
            updatedAt: Date()
        )

        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message: [String: Any] = ["watchState": data]

        guard let session, session.activationState == .activated else { return }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil)
            lastSentDate = Date()
        }

        do {
            try session.updateApplicationContext(message)
            lastSentDate = Date()
        } catch {
            // silently fail
        }
    }
}

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["request"] as? String == "update" {
            Task { @MainActor in
                if let state = self.pendingState, let data = try? JSONEncoder().encode(state) {
                    session.sendMessage(["watchState": data], replyHandler: nil)
                }
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["request"] as? String == "update" {
            Task { @MainActor in
                if let state = self.pendingState, let data = try? JSONEncoder().encode(state) {
                    replyHandler(["watchState": data])
                } else {
                    replyHandler(["status": "no_data"])
                }
            }
        } else {
            replyHandler(["status": "ok"])
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
        }
    }
}

nonisolated struct WatchStatePayload: Codable, Sendable {
    let nextPrayerKey: String
    let nextPrayerAr: String
    let nextPrayerEn: String
    let countdownSeconds: Int
    let phase: String
    let city: String
    let prayers: [WatchPrayerEntryPayload]
    let updatedAt: Date
}

nonisolated struct WatchPrayerEntryPayload: Codable, Sendable {
    let prayerKey: String
    let nameEn: String
    let nameAr: String
    let time: Date
    let icon: String
}
