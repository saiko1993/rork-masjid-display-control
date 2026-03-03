import SwiftUI
import Combine
import WebKit

struct PreviewView: View {
    let store: AppStore
    var connectionManager: ConnectionManager?

    @State private var currentTime: Date = Date()
    @State private var keepAwake: Bool = true
    @State private var useSimulatedTime: Bool = false
    @State private var simulatedTime: Date = Date()
    @State private var previewMode: PreviewMode = .liveServer
    @State private var selectedPresetId: String = "1080p"
    @State private var showDebugBadge: Bool = false
    @State private var refreshTrigger: Int = 0
    @State private var serverReachable: Bool = false
    @State private var checkingServer: Bool = false
    @State private var showMirrorMode: Bool = false
    @State private var forceReloadTrigger: Int = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var effectiveTime: Date {
        if store.demoMode, let demoTime = store.simulatedTime {
            return demoTime
        }
        return useSimulatedTime ? simulatedTime : currentTime
    }

    private var htmlContent: String {
        PreviewHTMLBuilder.buildHTML(store: store, now: effectiveTime)
    }

    private var displayURL: URL? {
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: base + "/display")
    }

    var body: some View {
        VStack(spacing: 0) {
            controlBar
            previewContent
        }
        .background(Color.black)
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showMirrorMode = true
                    } label: {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.subheadline.weight(.medium))
                    }

                    Menu {
                        Button {
                            refreshTrigger += 1
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                        }
                        Button {
                            forceReloadTrigger += 1
                        } label: {
                            Label("Force Reload (Clear Cache)", systemImage: "trash.circle")
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMirrorMode) {
            MirrorModeView(store: store, connectionManager: connectionManager)
        }
        .onReceive(timer) { currentTime = $0 }
        .onAppear {
            if store.prayerSchedule.isEmpty {
                store.regenerateSchedule()
            }
            checkServerReachability()
            if keepAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var controlBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                ForEach(PreviewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            previewMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                            Text(mode.label)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .minimumScaleFactor(0.85)
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(height: 56)
                        .background(previewMode == mode ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.ultraThinMaterial))
                        .clipShape(.capsule)
                    }
                }

                Divider().frame(height: 20)

                if store.demoMode {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(.purple)
                        Text("Demo")
                            .font(.caption.weight(.medium))
                        Button {
                            store.advanceDemoPhase()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                } else {
                    Toggle(isOn: $useSimulatedTime) {
                        Label("Sim", systemImage: "clock.arrow.circlepath")
                            .font(.caption.weight(.medium))
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    if useSimulatedTime {
                        DatePicker("", selection: $simulatedTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                }

                Divider().frame(height: 20)

                Menu {
                    ForEach(ThemeId.allCases, id: \.self) { themeId in
                        Button {
                            store.selectedTheme = themeId
                        } label: {
                            HStack {
                                Text(themeId.displayName)
                                if store.selectedTheme == themeId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("Theme", systemImage: "paintpalette")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                }

                Button {
                    keepAwake.toggle()
                    UIApplication.shared.isIdleTimerDisabled = keepAwake
                } label: {
                    Image(systemName: keepAwake ? "lock.display" : "display")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(keepAwake ? AnyShapeStyle(.tint.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial))
                        .clipShape(.capsule)
                }

                if previewMode == .nativeRenderer {
                    Divider().frame(height: 20)

                    Menu {
                        ForEach(ScreenPreset.presets) { preset in
                            Button(preset.name) {
                                selectedPresetId = preset.id
                            }
                        }
                    } label: {
                        Label(
                            ScreenPreset.presets.first { $0.id == selectedPresetId }?.name ?? "",
                            systemImage: "rectangle.dashed"
                        )
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                    }

                    Button {
                        showDebugBadge.toggle()
                    } label: {
                        Image(systemName: showDebugBadge ? "ladybug.fill" : "ladybug")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(showDebugBadge ? AnyShapeStyle(.tint.opacity(0.2)) : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(.capsule)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
        }
        .frame(height: 56)
        .background(.black.opacity(0.85))
    }

    @ViewBuilder
    private var previewContent: some View {
        switch previewMode {
        case .liveServer:
            liveServerPreview
        case .localHTML:
            localHTMLPreview
        case .nativeRenderer:
            nativePreview
        }
    }

    private var liveServerPreview: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if let url = displayURL, serverReachable {
                    LiveDisplayWebView(url: url, refreshTrigger: refreshTrigger, forceReloadTrigger: forceReloadTrigger)
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(8)
                } else if checkingServer {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.large)
                        Text("Connecting to display...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    nativeOfflineFallback
                }

                demoBadge(in: geo)
            }
        }
    }

    private var localHTMLPreview: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                WebPreviewView(htmlContent: htmlContent)
                    .clipShape(.rect(cornerRadius: 8))
                    .padding(8)

                demoBadge(in: geo)
            }
        }
    }

    private var nativePreview: some View {
        let preset = ScreenPreset.presets.first { $0.id == selectedPresetId } ?? ScreenPreset.presets[0]
        let tw = CGFloat(preset.width)
        let th = CGFloat(preset.height)

        return GeometryReader { geo in
            let aspect = tw / th
            let availW = geo.size.width - 16
            let availH = geo.size.height - 16
            let fitW = min(availW, availH * aspect)
            let fitH = fitW / aspect
            let scale = fitW / tw

            ZStack {
                Color.black

                DisplayRendererView(
                    store: store,
                    theme: store.currentTheme,
                    screenWidth: tw,
                    screenHeight: th,
                    now: effectiveTime
                )
                .frame(width: tw, height: th)
                .scaleEffect(scale, anchor: .center)
                .frame(width: fitW, height: fitH)

                if store.demoMode {
                    VStack {
                        HStack {
                            Spacer()
                            Text("DEMO")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.red.opacity(0.8))
                                .clipShape(.capsule)
                                .padding(8)
                        }
                        Spacer()
                    }
                    .frame(width: fitW, height: fitH)
                }

                if showDebugBadge {
                    VStack {
                        Spacer()
                        HStack {
                            debugBadgeContent
                            Spacer()
                        }
                    }
                    .frame(width: fitW, height: fitH)
                    .padding(8)
                }
            }
            .frame(width: fitW, height: fitH)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: store.currentTheme.palette.accent.opacity(0.15), radius: 20, y: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func demoBadge(in geo: GeometryProxy) -> some View {
        if store.demoMode {
            VStack {
                HStack {
                    Spacer()
                    Text("DEMO")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.8))
                        .clipShape(.capsule)
                        .padding(16)
                }
                Spacer()
            }
        }
    }

    private var debugBadgeContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            debugRow(label: "Theme", value: store.currentTheme.nameEn, ok: true)
            debugRow(label: "Schedule", value: "\(store.prayerSchedule.count) prayers", ok: !store.prayerSchedule.isEmpty)
            debugRow(label: "Phase", value: store.stateInfo.phase.rawValue, ok: true)
            debugRow(label: "Gradient", value: "\(store.currentTheme.layers.gradientStops.count) stops", ok: store.currentTheme.layers.gradientStops.count >= 2)
        }
        .padding(8)
        .background(.black.opacity(0.8))
        .clipShape(.rect(cornerRadius: 8))
    }

    private func debugRow(label: String, value: String, ok: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 9))
                .foregroundStyle(ok ? .green : .red)
            Text("\(label): \(value)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white)
        }
    }

    private var nativeOfflineFallback: some View {
        let preset = ScreenPreset.presets.first { $0.id == selectedPresetId } ?? ScreenPreset.presets[0]
        let tw = CGFloat(preset.width)
        let th = CGFloat(preset.height)

        return GeometryReader { geo in
            let aspect = tw / th
            let availW = geo.size.width - 16
            let availH = geo.size.height - 16
            let fitW = min(availW, availH * aspect)
            let fitH = fitW / aspect
            let scale = fitW / tw

            ZStack {
                Color.black

                DisplayRendererView(
                    store: store,
                    theme: store.currentTheme,
                    screenWidth: tw,
                    screenHeight: th,
                    now: effectiveTime
                )
                .frame(width: tw, height: th)
                .scaleEffect(scale, anchor: .center)
                .frame(width: fitW, height: fitH)

                VStack {
                    Spacer()
                    HStack(spacing: DS.Spacing.sm) {
                        Button {
                            checkServerReachability()
                        } label: {
                            Label("Retry Server", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .controlSize(.small)
                    }
                    .padding(DS.Spacing.sm)
                }
                .frame(width: fitW, height: fitH)
            }
            .frame(width: fitW, height: fitH)
            .clipShape(.rect(cornerRadius: 8))
            .shadow(color: store.currentTheme.palette.accent.opacity(0.15), radius: 20, y: 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func checkServerReachability() {
        let base = store.pushTarget.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/v1/info") else {
            serverReachable = false
            return
        }
        checkingServer = true
        Task {
            var request = URLRequest(url: url)
            request.timeoutInterval = 3
            request.setValue(store.pushTarget.apiKey, forHTTPHeaderField: "X-API-Key")
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                let http = response as? HTTPURLResponse
                serverReachable = http != nil && (200...299).contains(http!.statusCode)
            } catch {
                serverReachable = false
            }
            checkingServer = false

            if !serverReachable && previewMode == .liveServer {
                withAnimation { previewMode = .nativeRenderer }
            }
        }
    }
}

nonisolated enum PreviewMode: String, CaseIterable, Sendable {
    case liveServer
    case localHTML
    case nativeRenderer

    var label: String {
        switch self {
        case .liveServer: return "Live Display"
        case .localHTML: return "Local HTML"
        case .nativeRenderer: return "Native"
        }
    }

    var icon: String {
        switch self {
        case .liveServer: return "antenna.radiowaves.left.and.right"
        case .localHTML: return "globe"
        case .nativeRenderer: return "tv"
        }
    }
}
