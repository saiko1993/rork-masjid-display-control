import SwiftUI

@main
struct MasjidDisplayControlApp: App {
    @State private var store = AppStore()
    @State private var bleManager = BLEManager()
    @State private var connectionManager = ConnectionManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var toastManager = ToastManager()
    @State private var backgroundManager = BackgroundManager()

    var body: some Scene {
        WindowGroup {
            ContentView(
                store: store,
                bleManager: bleManager,
                connectionManager: connectionManager,
                networkMonitor: networkMonitor,
                toastManager: toastManager,
                backgroundManager: backgroundManager
            )
        }
    }
}
