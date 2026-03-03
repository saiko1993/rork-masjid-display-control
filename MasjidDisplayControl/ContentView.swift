import SwiftUI
import PopupView

enum AppTab: String, CaseIterable {
    case home, preview, push, settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .preview: return "Preview"
        case .push: return "Devices"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "moon.stars.fill"
        case .preview: return "tv.fill"
        case .push: return "antenna.radiowaves.left.and.right"
        case .settings: return "gearshape.fill"
        }
    }
}

enum AppRoute: Hashable {
    case setup
    case themes
    case docs
    case about
    case diagnostics
    case themeDetail(ThemeId)
    case themeEditor(ThemeId)
    case themeStudio(ThemeId)
    case facePicker
    case faceEditor(FaceId)
}

struct ContentView: View {
    @State private var store = AppStore()
    @State private var bleManager = BLEManager()
    @State private var connectionManager = ConnectionManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var toastManager = ToastManager()
    @State private var watchSync = WatchSyncService()
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var pushPath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    @State private var watchSyncTask: Task<Void, Never>? = nil

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack(path: $homePath) {
                    HomeView(store: store, connectionManager: connectionManager, bleManager: bleManager, networkMonitor: networkMonitor, toastManager: toastManager)
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                }
            }

            Tab(AppTab.preview.title, systemImage: AppTab.preview.icon, value: .preview) {
                NavigationStack {
                    PreviewView(store: store, connectionManager: connectionManager)
                }
            }

            Tab(AppTab.push.title, systemImage: AppTab.push.icon, value: .push) {
                NavigationStack(path: $pushPath) {
                    PushView(store: store, bleManager: bleManager, connectionManager: connectionManager, networkMonitor: networkMonitor, toastManager: toastManager)
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                }
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                NavigationStack(path: $settingsPath) {
                    SettingsView(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                }
            }
        }
        .popupToasts(manager: toastManager)
        .tint(.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            networkMonitor.start()
            connectionManager.startMonitoring(store: store)
            watchSync.sendState(from: store)
            watchSyncTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
                    guard !Task.isCancelled else { return }
                    watchSync.sendState(from: store)
                }
            }
        }
        .onDisappear {
            networkMonitor.stop()
            watchSyncTask?.cancel()
        }
    }
}

struct RouteDestinationModifier: ViewModifier {
    let store: AppStore
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    let toastManager: ToastManager

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .setup:
                    SetupWizardView(store: store)
                case .themes:
                    ThemesView(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                case .docs:
                    DocsView()
                case .about:
                    AboutView()
                case .diagnostics:
                    DiagnosticsView(store: store, connectionManager: connectionManager)
                case .themeDetail(let themeId):
                    ThemeDetailView(store: store, themeId: themeId, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                case .themeEditor(let themeId):
                    ThemeEditorView(store: store, themeId: themeId, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                case .themeStudio(let themeId):
                    ThemeStudioView(store: store, themeId: themeId, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                case .facePicker:
                    FacePickerView(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                case .faceEditor(let faceId):
                    FaceEditorView(store: store, faceId: faceId, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                }
            }
            .navigationDestination(for: DocSection.self) { section in
                DocDetailView(section: section)
            }
    }
}

extension View {
    func applyRouteDestinations(store: AppStore, connectionManager: ConnectionManager, bleManager: BLEManager, toastManager: ToastManager) -> some View {
        modifier(RouteDestinationModifier(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager))
    }
}
