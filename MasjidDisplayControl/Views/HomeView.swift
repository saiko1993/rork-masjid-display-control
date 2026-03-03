import SwiftUI
import Combine
import SwiftUIX

struct HomeView: View {
    let store: AppStore
    var connectionManager: ConnectionManager?
    var bleManager: BLEManager?
    var networkMonitor: NetworkMonitor?
    var toastManager: ToastManager?

    @State private var currentTime: Date = Date()
    @State private var appearAnim: Bool = false
    @State private var isSendingTheme: Bool = false
    @State private var isSendingSync: Bool = false
    @State private var isReconnecting: Bool = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                heroSection
                    .staggerAppear(visible: appearAnim, index: 0)

                connectionStatusCard
                    .staggerAppear(visible: appearAnim, index: 1)

                nextPrayerCard
                    .staggerAppear(visible: appearAnim, index: 2)
                    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.3), trigger: store.stateInfo.phase)

                quickChipsRow

                primaryActionsRow
                    .staggerAppear(visible: appearAnim, index: 3)

                demoModeCard

                quickActionsGrid
                    .staggerAppear(visible: appearAnim, index: 4)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: store.currentTheme.palette.accent) { Color.clear })
        .navigationTitle("Masjid Controller")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.about) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .onReceive(timer) { currentTime = $0 }
        .onAppear {
            withAnimation(DSAnimation.appear) {
                appearAnim = true
            }
        }
    }

    private var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    store.currentTheme.palette.accent.opacity(0.12),
                    .clear,
                    store.currentTheme.palette.accent.opacity(0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))

            IslamicPatternView(
                pattern: store.currentTheme.backgroundPattern,
                color: store.currentTheme.palette.primary,
                scaleFactor: 0.25,
                opacity: store.currentTheme.layers.patternOpacity * 0.4
            )
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))

            RadialGradient(
                colors: [store.currentTheme.palette.accent.opacity(0.15), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 180
            )
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))

            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(store.currentTheme.palette.accent)
                    .symbolEffect(.pulse.byLayer)

                Text("بسم الله الرحمن الرحيم")
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
                    .environment(\.layoutDirection, .rightToLeft)

                Text(store.currentTheme.nameEn)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(store.currentTheme.palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(store.currentTheme.palette.accent.opacity(0.15))
                    .clipShape(.capsule)
            }
        }
        .frame(height: 150)
        .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [store.currentTheme.palette.accent.opacity(0.2), store.currentTheme.palette.accent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .elevation(.level3, color: store.currentTheme.palette.accent)
        .shimmer()
    }

    @ViewBuilder
    private var connectionStatusCard: some View {
        if let cm = connectionManager {
            let isError = cm.connectionState == .error
            DSCard(glow: connectionColor(cm.connectionState)) {
                HStack(spacing: DS.Spacing.sm) {
                    ConnectionPulseView(
                        isConnected: cm.connectionState == .connected,
                        color: connectionColor(cm.connectionState)
                    )
                    .frame(width: 14, height: 14)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(connectionLabel(cm.connectionState))
                                .font(.subheadline.weight(.semibold))
                            if cm.isPaired {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                        if let date = cm.lastSyncDate {
                            Text("Last sync: \(date, style: .relative) ago")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if cm.connectionState == .syncing {
                        ProgressView().controlSize(.small)
                    }

                    if let nm = networkMonitor {
                        StatusChip(nm.isConnected ? nm.interfaceType : "Offline", color: nm.isConnected ? .cyan : .red, icon: nm.isConnected ? "wifi" : "wifi.slash")
                    }

                    if cm.connectionState == .connected && cm.serverResponseTimeMs > 0 {
                        StatusChip("\(cm.serverResponseTimeMs)ms", color: cm.serverResponseTimeMs < 200 ? .green : .orange, icon: "bolt.fill")
                    }

                    if cm.pendingCount > 0 {
                        StatusChip("\(cm.pendingCount)", color: .orange, icon: "tray.full.fill")
                            .accessibilityLabel("Queue: \(cm.pendingCount)")
                    }

                    if cm.connectionState == .disconnected || cm.connectionState == .error {
                        Button {
                            isReconnecting = true
                            Task {
                                await cm.reconnect(store: store)
                                isReconnecting = false
                                if cm.connectionState == .connected {
                                    toastManager?.show(.success, message: "Connected to display")
                                } else {
                                    toastManager?.show(.error, message: cm.lastError ?? "Connection failed")
                                }
                            }
                        } label: {
                            if isReconnecting {
                                ProgressView().controlSize(.small)
                            } else {
                                Label("Reconnect", systemImage: "arrow.clockwise")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.cyan)
                        .disabled(isReconnecting)
                    }
                }
            }
            .focusRing(isActive: isError, color: .red)
            .errorFocus(isError: isError)
        }
    }

    private var nextPrayerCard: some View {
        let state = PrayerStateMachine.evaluate(
            now: store.demoMode ? (store.simulatedTime ?? currentTime) : currentTime,
            schedule: store.prayerSchedule,
            adhanActiveSeconds: store.advanced.adhanActiveSeconds,
            iqamaConfig: store.iqama,
            prayerInProgressMinutes: store.advanced.prayerInProgressMinutes
        )

        return DSCard(glow: phaseColor(state.phase)) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(phaseColor(state.phase).opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: phaseIcon(state.phase))
                                .font(.system(size: 20))
                                .foregroundStyle(phaseColor(state.phase))
                                .symbolEffect(.pulse, options: .repeating, value: state.phase == .adhanActive)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.phase == .normal ? "Next Prayer" : "Current State")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(store.display.language == .ar ? state.phaseLabelAr : state.phaseLabel)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }

                    Spacer()

                    if state.phase == .normal && state.countdownSeconds > 0 {
                        Text(formatCountdown(state.countdownSeconds))
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                            .vibrancyText(isActive: true, color: .cyan)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.default, value: state.countdownSeconds)
                    } else if state.phase == .adhanActive {
                        Text(formatCountdown(state.adhanRemainingSeconds))
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .vibrancyText(isActive: true, color: .orange)
                            .monospacedDigit()
                    } else if state.phase == .iqamaCountdown {
                        Text(formatCountdown(state.iqamaCountdownSeconds))
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                            .vibrancyText(isActive: true, color: .purple)
                            .monospacedDigit()
                    }
                }

                if state.phase != .normal {
                    ProgressView(value: phaseProgress(state))
                        .tint(phaseColor(state.phase))
                }
            }
        }
        .focusPulse(isActive: state.phase != .normal, color: phaseColor(state.phase))
    }

    private var quickChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                StatusChip(store.location.cityName, color: .blue, icon: "location.fill")
                StatusChip(store.currentTheme.nameEn, color: .orange, icon: "paintpalette.fill")
                StatusChip(store.display.layout.displayName, color: .indigo, icon: "rectangle.split.2x1")
                StatusChip("Bright: \(store.display.brightness)%", color: .yellow, icon: "sun.max.fill")
                if store.advanced.scheduleMode == "simulated" {
                    StatusChip("SIM", color: .orange, icon: "clock.badge.questionmark")
                }
                if isFriday && store.jumuah.enabled {
                    StatusChip("Jumu'ah \(store.jumuah.jumuahTime)", color: .green, icon: "building.columns.fill")
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    @ViewBuilder
    private var primaryActionsRow: some View {
        if let cm = connectionManager, let bm = bleManager {
            HStack(spacing: DS.Spacing.sm) {
                DSActionTileButton(
                    icon: "paintpalette.fill",
                    title: isSendingTheme ? "Sending..." : "Send Theme",
                    tint: .orange,
                    isLoading: isSendingTheme,
                    isDisabled: cm.connectionState != .connected
                ) {
                    isSendingTheme = true
                    toastManager?.show(.syncing, message: "Sending theme pack...")
                    Task {
                        await cm.sendThemePack(store: store, bleManager: bm)
                        isSendingTheme = false
                        if cm.connectionState == .connected {
                            toastManager?.show(.success, message: "Theme pack sent")
                        } else {
                            toastManager?.show(.error, message: cm.lastError ?? "Failed to send theme")
                        }
                    }
                }

                DSActionTileButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: isSendingSync ? "Syncing..." : "Light Sync",
                    tint: .cyan,
                    isLoading: isSendingSync,
                    isDisabled: cm.connectionState != .connected
                ) {
                    isSendingSync = true
                    toastManager?.show(.syncing, message: "Syncing...")
                    Task {
                        await cm.sendLightSync(store: store, bleManager: bm)
                        isSendingSync = false
                        if cm.connectionState == .connected {
                            toastManager?.show(.success, message: "Light sync complete")
                        } else {
                            toastManager?.show(.error, message: cm.lastError ?? "Sync failed")
                        }
                    }
                }

                DSActionTileButton(
                    icon: store.saveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down.fill",
                    title: store.saveConfirmation ? "Saved!" : "Save All",
                    tint: store.saveConfirmation ? .green : .cyan
                ) {
                    store.save()
                    cm.scheduleLightSync(store: store, bleManager: bm)
                    toastManager?.show(.success, message: "Settings saved")
                }
                .sensoryFeedback(.success, trigger: store.saveConfirmation)
            }
        }
    }

    private var demoModeCard: some View {
        DSCard(glow: store.demoMode ? .purple : nil) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.purple)
                        }
                        Text("Demo Mode")
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()

                    if store.demoMode {
                        Button {
                            withAnimation(DSAnimation.softEase) { store.stopDemoMode() }
                        } label: {
                            Text("Stop")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                    } else {
                        Button {
                            withAnimation(DSAnimation.softEase) { store.startDemoMode() }
                        } label: {
                            Text("Start")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        .controlSize(.small)
                    }
                }

                if store.demoMode {
                    HStack {
                        let state = store.stateInfo
                        Image(systemName: phaseIcon(state.phase))
                            .foregroundStyle(phaseColor(state.phase))
                        Text(state.phaseLabel)
                            .font(.caption)
                        Spacer()
                        Button {
                            withAnimation { store.advanceDemoPhase() }
                        } label: {
                            Label("Next", systemImage: "forward.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Text("Preview adhan, iqama, and prayer states instantly.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .focusPulse(isActive: store.demoMode, color: .purple)
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
            NavigationLink(value: AppRoute.setup) {
                ActionTileView(icon: "wand.and.stars", title: "Setup", subtitle: "Wizard", color: .purple)
            }
            .buttonStyle(PressEffectStyle())

            NavigationLink(value: AppRoute.facePicker) {
                ActionTileView(icon: "rectangle.grid.2x2.fill", title: "Face Studio", subtitle: "6 faces", color: .purple)
            }
            .buttonStyle(PressEffectStyle())

            NavigationLink(value: AppRoute.themes) {
                ActionTileView(icon: "paintpalette.fill", title: "Themes", subtitle: "\(ThemeId.allCases.count) themes", color: .orange)
            }
            .buttonStyle(PressEffectStyle())

            NavigationLink(value: AppRoute.docs) {
                ActionTileView(icon: "doc.text.fill", title: "Docs", subtitle: "PRD & Guide", color: .indigo)
            }
            .buttonStyle(PressEffectStyle())

            Button {
                store.regenerateSchedule()
                store.save()
            } label: {
                ActionTileView(icon: "arrow.clockwise", title: "Refresh", subtitle: "Schedule", color: .green)
            }
            .buttonStyle(PressEffectStyle())
            .sensoryFeedback(.impact(flexibility: .soft), trigger: store.prayerSchedule.count)
        }
    }

    private func formatCountdown(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private var isFriday: Bool {
        Calendar.current.component(.weekday, from: Date()) == 6
    }

    private func phaseIcon(_ phase: PrayerPhase) -> String {
        switch phase {
        case .normal: return "clock.fill"
        case .adhanActive: return "speaker.wave.3.fill"
        case .iqamaCountdown: return "bell.fill"
        case .prayerInProgress: return "person.fill"
        }
    }

    private func phaseColor(_ phase: PrayerPhase) -> Color {
        switch phase {
        case .normal: return .cyan
        case .adhanActive: return .orange
        case .iqamaCountdown: return .purple
        case .prayerInProgress: return .green
        }
    }

    private func phaseProgress(_ state: PrayerStateInfo) -> Double {
        switch state.phase {
        case .adhanActive:
            let total = Double(store.advanced.adhanActiveSeconds)
            let remaining = Double(state.adhanRemainingSeconds)
            return total > 0 ? (total - remaining) / total : 0
        case .iqamaCountdown:
            guard let prayer = state.currentPrayer else { return 0 }
            let total = Double(store.iqama.iqamaMinutes.minutes(for: prayer)) * 60
            let remaining = Double(state.iqamaCountdownSeconds)
            return total > 0 ? (total - remaining) / total : 0
        case .prayerInProgress:
            let total = Double(store.advanced.prayerInProgressMinutes) * 60
            let remaining = Double(state.countdownSeconds)
            return total > 0 ? (total - remaining) / total : 0
        default:
            return 0
        }
    }

    private func connectionColor(_ state: SyncConnectionState) -> Color {
        switch state {
        case .connected: return .green
        case .syncing: return .cyan
        case .searching: return .orange
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private func connectionLabel(_ state: SyncConnectionState) -> String {
        switch state {
        case .connected: return "Connected to Display"
        case .syncing: return "Syncing..."
        case .searching: return "Searching..."
        case .error: return connectionManager?.lastError ?? "Error"
        case .disconnected: return "Not Connected"
        }
    }
}
