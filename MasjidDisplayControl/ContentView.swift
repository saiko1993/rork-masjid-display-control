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
    case backgroundGallery
}

struct ContentView: View {
    let store: AppStore
    let bleManager: BLEManager
    let connectionManager: ConnectionManager
    let networkMonitor: NetworkMonitor
    let toastManager: ToastManager
    let backgroundManager: BackgroundManager

    @State private var watchSync = WatchSyncService()
    @State private var selectedTab: AppTab = .home
    @State private var homePath = NavigationPath()
    @State private var pushPath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    @State private var watchSyncTask: Task<Void, Never>? = nil
    @State private var isReady: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack(path: $homePath) {
                    HomeView(store: store, connectionManager: connectionManager, bleManager: bleManager, networkMonitor: networkMonitor, toastManager: toastManager, backgroundManager: backgroundManager)
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager, backgroundManager: backgroundManager)
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
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager, backgroundManager: backgroundManager)
                }
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.icon, value: .settings) {
                NavigationStack(path: $settingsPath) {
                    SettingsView(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager)
                        .applyRouteDestinations(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager, backgroundManager: backgroundManager)
                }
            }
        }
        .popupToasts(manager: toastManager)
        .tint(DSTokens.Palette.accent)
        .preferredColorScheme(.dark)
        .onAppear {
            networkMonitor.start()
            connectionManager.startMonitoring(store: store)
            backgroundManager.ensureStockAssets(in: &store.backgroundConfig)
            if let active = store.backgroundConfig.activeBackground, active.type == .photo {
                backgroundManager.loadImage(for: active)
            }
            watchSync.sendState(from: store)
            watchSyncTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
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
    let backgroundManager: BackgroundManager

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
                case .backgroundGallery:
                    BackgroundGalleryView(store: store, backgroundManager: backgroundManager, toastManager: toastManager)
                }
            }
            .navigationDestination(for: DocSection.self) { section in
                DocDetailView(section: section)
            }
    }
}

extension View {
    func applyRouteDestinations(store: AppStore, connectionManager: ConnectionManager, bleManager: BLEManager, toastManager: ToastManager, backgroundManager: BackgroundManager) -> some View {
        modifier(RouteDestinationModifier(store: store, connectionManager: connectionManager, bleManager: bleManager, toastManager: toastManager, backgroundManager: backgroundManager))
    }
}
