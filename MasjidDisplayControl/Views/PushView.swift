import SwiftUI
import CoreBluetooth
import SwiftUIX

enum ConnectionStatus: Equatable {
    case idle, testing, success, failure(String)
}

struct PushView: View {
    @Bindable var store: AppStore
    let bleManager: BLEManager
    @Bindable var connectionManager: ConnectionManager
    var networkMonitor: NetworkMonitor?
    var toastManager: ToastManager?
    @State private var pushService = PushService()
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var showPayload: Bool = false
    @State private var selectedPayloadType: PushType = .lightSync
    @State private var showHistory: Bool = false
    @State private var showBLESheet: Bool = false
    @State private var appearAnimation: Bool = false
    @State private var pairingInProgress: Bool = false
    @State private var showPairSuccess: Bool = false
    @State private var isReconnecting: Bool = false
    @State private var isSendingTheme: Bool = false
    @State private var isSendingSync: Bool = false

    private var payloadJSON: String {
        switch selectedPayloadType {
        case .themePack:
            return PayloadBuilder.toJSON(PayloadBuilder.buildThemePack(from: store))
        case .lightSync:
            return PayloadBuilder.toJSON(PayloadBuilder.buildLightSync(from: store))
        default:
            return "{}"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                connectionCard
                primaryActionsSection
                autoSyncSection
                transportSection
                bleSection
                wifiConfigSection
                syncActionsSection
                payloadSection
                historySection
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: store.currentTheme.palette.accent) { Color.clear })
        .navigationTitle("Devices")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if pushService.isSending || pairingInProgress {
                        ProgressView().controlSize(.small)
                    }
                    NavigationLink(value: AppRoute.diagnostics) {
                        Image(systemName: "stethoscope")
                    }
                }
            }
        }
        .sheet(isPresented: $showBLESheet) {
            BLEScanSheet(bleManager: bleManager, store: store)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
        .onAppear {
            withAnimation(DSAnimation.appear) {
                appearAnimation = true
            }
        }
    }

    private var connectionCard: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(connectionGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: connectionAccentColor.opacity(0.4), radius: 20)

                if connectionManager.connectionState == .searching {
                    PulseRingView(color: .blue, isAnimating: true)
                        .frame(width: 96, height: 96)
                }

                Image(systemName: connectionStateIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: connectionManager.connectionState == .connected)
            }
            .frame(height: 100)

            VStack(spacing: 4) {
                Text(connectionStateTitle)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(connectionStateSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            HStack(spacing: DS.Spacing.sm) {
                if let nm = networkMonitor {
                    statusPill(
                        nm.isConnected ? nm.interfaceType : "–",
                        icon: nm.isConnected ? "wifi" : "wifi.slash",
                        isActive: nm.isConnected,
                        color: nm.isConnected ? .cyan : .red
                    )
                }
                statusPill(
                    connectionManager.connectionState == .connected ? "OK" : "–",
                    icon: connectionManager.connectionState == .connected ? "checkmark.circle.fill" : "xmark.circle",
                    isActive: connectionManager.connectionState == .connected,
                    color: connectionManager.connectionState == .connected ? .green : .secondary
                )
                if connectionManager.isPaired {
                    statusPill("", icon: "checkmark.seal.fill", isActive: true, color: .green)
                }
                if connectionManager.pendingCount > 0 {
                    statusPill("\(min(connectionManager.pendingCount, 99))", icon: "tray.full.fill", isActive: true, color: .orange)
                }
                if connectionManager.serverResponseTimeMs > 0 && connectionManager.connectionState == .connected {
                    statusPill("\(connectionManager.serverResponseTimeMs)ms", icon: "bolt.fill", isActive: true, color: connectionManager.serverResponseTimeMs < 200 ? .green : .orange)
                }
            }
        }
        .padding(DS.Spacing.lg)
        .glassLayer(.window, glow: connectionAccentColor)
        .elevation(.level3, color: connectionAccentColor)
        .staggerAppear(visible: appearAnimation, index: 0)
    }

    private var primaryActionsSection: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Button {
                    isReconnecting = true
                    Task {
                        await connectionManager.reconnect(store: store)
                        isReconnecting = false
                        if connectionManager.connectionState == .connected {
                            toastManager?.show(.success, message: "Connected to display")
                        } else {
                            toastManager?.show(.error, message: connectionManager.lastError ?? "Connection failed")
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        if isReconnecting {
                            ProgressView().controlSize(.regular)
                                .frame(height: 28)
                        } else {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 28))
                        }
                        Text(isReconnecting ? "Connecting..." : "Reconnect")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(connectionManager.connectionState == .searching || isReconnecting)

                Button {
                    pairingInProgress = true
                    toastManager?.show(.syncing, message: "Pairing with display...")
                    Task {
                        let success = await connectionManager.pairDevice(store: store, bleManager: bleManager)
                        pairingInProgress = false
                        if success {
                            showPairSuccess = true
                            toastManager?.show(.success, message: "Successfully paired with display")
                            try? await Task.sleep(for: .seconds(2))
                            showPairSuccess = false
                        } else {
                            toastManager?.show(.error, message: connectionManager.lastError ?? "Pairing failed")
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: showPairSuccess ? "checkmark.circle.fill" : "link.badge.plus")
                            .font(.system(size: 28))
                            .foregroundStyle(showPairSuccess ? .green : .white)
                        Text(showPairSuccess ? "Paired!" : "Pair")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                }
                .buttonStyle(.borderedProminent)
                .tint(showPairSuccess ? .green : .indigo)
                .disabled(pairingInProgress)
                .sensoryFeedback(.success, trigger: showPairSuccess)
            }

            HStack(spacing: DS.Spacing.sm) {
                Button {
                    isSendingTheme = true
                    toastManager?.show(.syncing, message: "Sending theme pack...")
                    Task {
                        await connectionManager.sendThemePack(store: store, bleManager: bleManager)
                        isSendingTheme = false
                        if connectionManager.connectionState == .connected || connectionManager.connectionState == .syncing {
                            toastManager?.show(.success, message: "Theme pack sent")
                        } else {
                            toastManager?.show(.error, message: connectionManager.lastError ?? "Theme send failed")
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        if isSendingTheme {
                            ProgressView().controlSize(.small)
                                .frame(height: 24)
                        } else {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 24))
                        }
                        Text(isSendingTheme ? "Sending..." : "Send Theme")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .disabled(connectionManager.connectionState != .connected || isSendingTheme)

                Button {
                    isSendingSync = true
                    toastManager?.show(.syncing, message: "Syncing...")
                    Task {
                        await connectionManager.sendLightSync(store: store, bleManager: bleManager)
                        isSendingSync = false
                        if connectionManager.connectionState == .connected || connectionManager.connectionState == .syncing {
                            toastManager?.show(.success, message: "Light sync complete")
                        } else {
                            toastManager?.show(.error, message: connectionManager.lastError ?? "Sync failed")
                        }
                    }
                } label: {
                    VStack(spacing: 8) {
                        if isSendingSync {
                            ProgressView().controlSize(.small)
                                .frame(height: 24)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 24))
                        }
                        Text(isSendingSync ? "Syncing..." : "Light Sync")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
                .disabled(connectionManager.connectionState != .connected || isSendingSync)

                Button {
                    store.save()
                    connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
                    toastManager?.show(.success, message: "Settings saved")
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: store.saveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(store.saveConfirmation ? .green : .blue)
                        Text(store.saveConfirmation ? "Saved!" : "Save")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                }
                .buttonStyle(.bordered)
                .tint(store.saveConfirmation ? .green : .blue)
                .sensoryFeedback(.success, trigger: store.saveConfirmation)
            }

            if let error = connectionManager.lastError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                }
                .padding(DS.Spacing.sm)
                .background(.orange.opacity(0.08))
                .clipShape(.rect(cornerRadius: DS.Radius.sm))
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .indigo)
        .elevation(.level2)
        .focusRing(isActive: connectionManager.lastError != nil, color: .orange)
        .staggerAppear(visible: appearAnimation, index: 1)
    }

    private var autoSyncSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Auto-Sync", icon: "arrow.triangle.2.circlepath", color: .mint)

            HStack(spacing: DS.Spacing.sm) {
                Circle()
                    .fill(autoSyncColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(autoSyncLabel)
                        .font(.subheadline.weight(.medium))
                    if let date = connectionManager.lastSyncDate {
                        Text("Last sync: \(date, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if connectionManager.connectionState == .syncing {
                    ProgressView().controlSize(.small)
                }

                Toggle("", isOn: Binding(
                    get: { connectionManager.isAutoSyncEnabled },
                    set: { connectionManager.isAutoSyncEnabled = $0 }
                ))
                .labelsHidden()
            }

            HStack(spacing: DS.Spacing.md) {
                if let d = connectionManager.lastThemePackDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme Pack")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(d, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                if let d = connectionManager.lastLightSyncDate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Light Sync")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(d, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .mint)
        .elevation(.level2)
        .staggerAppear(visible: appearAnimation, index: 2)
    }

    private var transportSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Transport Mode", icon: "arrow.triangle.branch", color: .blue)

            HStack(spacing: DS.Spacing.xs) {
                ForEach(TransportMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.pushTarget.transportMode = mode
                            store.save()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(store.pushTarget.transportMode == mode
                                          ? mode.accentColor.opacity(0.15)
                                          : Color(.tertiarySystemGroupedBackground))
                                    .frame(width: 44, height: 44)

                                Image(systemName: mode.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(store.pushTarget.transportMode == mode ? mode.accentColor : .secondary)
                            }

                            Text(mode.displayName)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(store.pushTarget.transportMode == mode ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                .fill(store.pushTarget.transportMode == mode ? mode.accentColor.opacity(0.06) : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                .strokeBorder(store.pushTarget.transportMode == mode ? mode.accentColor.opacity(0.2) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                    .sensoryFeedback(.selection, trigger: store.pushTarget.transportMode)
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .blue)
        .elevation(.level2)
        .staggerAppear(visible: appearAnimation, index: 3)
    }

    @ViewBuilder
    private var bleSection: some View {
        if store.pushTarget.transportMode == .bluetooth || store.pushTarget.transportMode == .auto {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack {
                    SectionHeader(title: "Bluetooth", icon: "antenna.radiowaves.left.and.right", color: .indigo)
                    Spacer()
                    bleStateBadge
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Device")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("MasjidDisplay", text: $store.pushTarget.bleDeviceName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                }

                HStack(spacing: DS.Spacing.sm) {
                    if bleManager.connectionState == .disconnected {
                        Button {
                            bleManager.start(targetName: store.pushTarget.bleDeviceName)
                            bleManager.startScanning()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                Text("Scan")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: bleManager.connectionState)
                    } else if bleManager.connectionState == .scanning {
                        Button {
                            bleManager.stopScanning()
                        } label: {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.small)
                                Text("Stop (\(String(format: "%.0f", bleManager.scanDuration))s)")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    } else if bleManager.isReady {
                        Button {
                            bleManager.disconnect()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle")
                                Text("Disconnect")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button {
                            bleManager.start(targetName: store.pushTarget.bleDeviceName)
                            bleManager.startScanning()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        showBLESheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                            Text("\(bleManager.discoveredDevices.count)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if !bleManager.discoveredDevices.isEmpty && bleManager.connectionState == .scanning {
                    quickDeviceList
                }

                if let error = bleManager.lastError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(DS.Spacing.sm)
                    .background(.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: DS.Radius.sm))
                }
            }
            .padding(DS.Spacing.md)
            .glassLayer(.card, glow: .indigo)
            .elevation(.level2)
            .staggerAppear(visible: appearAnimation, index: 4)
        }
    }

    private var quickDeviceList: some View {
        VStack(spacing: DS.Spacing.xs) {
            ForEach(bleManager.discoveredDevices.prefix(3)) { device in
                Button {
                    bleManager.connect(to: device)
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(device.isMasjidDevice ? .green.opacity(0.15) : .blue.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: device.isMasjidDevice ? "checkmark.seal.fill" : "antenna.radiowaves.left.and.right")
                                .font(.system(size: 14))
                                .foregroundStyle(device.isMasjidDevice ? .green : .blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(String(device.id.uuidString.prefix(8)))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        SignalStrengthView(rssi: device.rssi, color: device.isMasjidDevice ? .green : .blue)

                        Text("\(device.rssi) dBm")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(DS.Spacing.sm)
                    .background(device.isMasjidDevice ? Color.green.opacity(0.04) : Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: DS.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                            .strokeBorder(device.isMasjidDevice ? .green.opacity(0.2) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PressEffectStyle())
            }

            if bleManager.discoveredDevices.count > 3 {
                Button {
                    showBLESheet = true
                } label: {
                    Text("View all \(bleManager.discoveredDevices.count) devices")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private var bleStateBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(bleStateColor)
                .frame(width: 8, height: 8)
            Text(bleManager.connectionState.rawValue.capitalized)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(bleStateColor.opacity(0.1))
        .clipShape(.capsule)
    }

    private var bleStateColor: Color {
        switch bleManager.connectionState {
        case .disconnected: return .red
        case .scanning: return .orange
        case .connecting: return .yellow
        case .connected: return .blue
        case .ready: return .green
        }
    }

    private var wifiConfigSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "WiFi Connection", icon: "wifi", color: .cyan)

            VStack(spacing: DS.Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Base URL")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("http://masjidclock.local:8787", text: $store.pushTarget.baseUrl)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("API Key", text: $store.pushTarget.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.subheadline)
                }

                HStack(spacing: DS.Spacing.sm) {
                    Button {
                        testConnection()
                    } label: {
                        HStack(spacing: 6) {
                            if connectionStatus == .testing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text("Test Connection")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(connectionStatus == .testing)
                }

                connectionStatusBadge
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .cyan)
        .elevation(.level2)
        .staggerAppear(visible: appearAnimation, index: 5)
    }

    private var syncActionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Manual Sync", icon: "arrow.triangle.2.circlepath", color: .green)

            VStack(spacing: DS.Spacing.xs) {
                syncActionRow(
                    icon: "paintpalette.fill",
                    iconColor: .orange,
                    title: "Send Theme Pack",
                    subtitle: "Full theme definition + layer stack"
                ) {
                    Task { await pushService.sendThemePack(store: store, bleManager: bleManager) }
                }

                syncActionRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .blue,
                    title: "Send Light Sync",
                    subtitle: "Schedule + display config + time sync"
                ) {
                    Task { await pushService.sendLightSync(store: store, bleManager: bleManager) }
                }

                syncActionRow(
                    icon: "calendar.badge.clock",
                    iconColor: .green,
                    title: "Send Today's Schedule",
                    subtitle: "Prayer times for today only"
                ) {
                    Task { await pushService.sendLightSync(store: store, bleManager: bleManager) }
                }
            }

            if pushService.isSending {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Sending...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if pushService.retryCount > 0 {
                        StatusChip("Retry \(pushService.retryCount)/3", color: .orange)
                    }
                    if pushService.queueLength > 0 {
                        StatusChip("Queue: \(pushService.queueLength)", color: .blue)
                    }
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card, glow: .green)
        .elevation(.level2)
        .staggerAppear(visible: appearAnimation, index: 6)
    }

    private func syncActionRow(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            .padding(DS.Spacing.sm)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(PressEffectStyle())
        .disabled(pushService.isSending)
    }

    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Button {
                withAnimation(.spring(duration: 0.3)) { showPayload.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        Text("Payload Inspector")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: showPayload ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.quaternary)
                        .clipShape(.circle)
                }
            }
            .buttonStyle(.plain)

            if showPayload {
                Picker("Payload Type", selection: $selectedPayloadType) {
                    Text("Theme Pack").tag(PushType.themePack)
                    Text("Light Sync").tag(PushType.lightSync)
                }
                .pickerStyle(.segmented)

                ScrollView(.horizontal, showsIndicators: true) {
                    Text(payloadJSON)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.primary)
                        .padding(DS.Spacing.sm)
                }
                .frame(maxHeight: 250)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: DS.Radius.sm))

                HStack(spacing: DS.Spacing.sm) {
                    Button {
                        UIPasteboard.general.string = payloadJSON
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        let av = UIActivityViewController(activityItems: [payloadJSON], applicationActivities: nil)
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let vc = scene.windows.first?.rootViewController {
                            vc.present(av, animated: true)
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level1)
        .staggerAppear(visible: appearAnimation, index: 7)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Button {
                withAnimation(.spring(duration: 0.3)) { showHistory.toggle() }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text("Push History (\(pushService.pushHistory.count))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showHistory && !pushService.pushHistory.isEmpty {
                ForEach(pushService.pushHistory) { entry in
                    HStack(spacing: DS.Spacing.xs) {
                        Circle()
                            .fill(entry.status == .success ? .green : .red)
                            .frame(width: 8, height: 8)

                        Image(systemName: entry.pushType.icon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.message)
                                .font(.caption)
                                .lineLimit(1)
                            HStack(spacing: 4) {
                                Text(entry.pushType.displayName)
                                Text("·")
                                Text(entry.transport)
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Text(entry.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if showHistory && pushService.pushHistory.isEmpty {
                Text("No push history yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level1)
        .staggerAppear(visible: appearAnimation, index: 8)
    }

    @ViewBuilder
    private var connectionStatusBadge: some View {
        switch connectionStatus {
        case .idle, .testing:
            EmptyView()
        case .success:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
                .transition(.opacity)
        case .failure(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
                .transition(.opacity)
        }
    }

    private func statusPill(_ text: String, icon: String, isActive: Bool, color: Color) -> some View {
        HStack(spacing: text.isEmpty ? 0 : 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            if !text.isEmpty {
                Text(text)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isActive ? color.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
        .foregroundStyle(isActive ? color : .secondary)
        .clipShape(.capsule)
        .frame(minWidth: 36)
    }

    private var connectionGradient: some ShapeStyle {
        LinearGradient(
            colors: [connectionAccentColor, connectionAccentColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var connectionAccentColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .syncing: return .blue
        case .searching: return .orange
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private var connectionStateIcon: String {
        switch connectionManager.connectionState {
        case .connected: return "checkmark.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .searching: return "magnifyingglass"
        case .error: return "exclamationmark.triangle.fill"
        case .disconnected: return "wifi.slash"
        }
    }

    private var connectionStateTitle: String {
        switch connectionManager.connectionState {
        case .connected: return connectionManager.discoveredHost ?? "Connected"
        case .syncing: return "Syncing..."
        case .searching: return "Searching..."
        case .error: return "Connection Error"
        case .disconnected: return "Not Connected"
        }
    }

    private var connectionStateSubtitle: String {
        switch connectionManager.connectionState {
        case .connected: return connectionManager.isPaired ? "Paired and ready to sync" : "Connected — tap Pair to complete setup"
        case .syncing: return "Pushing changes to display..."
        case .searching: return "Looking for display on network..."
        case .error: return connectionManager.lastError ?? "Check your network connection"
        case .disconnected: return "Tap Reconnect to connect to your display"
        }
    }

    private var autoSyncColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .syncing: return .blue
        case .searching: return .orange
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private var autoSyncLabel: String {
        switch connectionManager.connectionState {
        case .connected: return connectionManager.isAutoSyncEnabled ? "Connected — Auto-sync active" : "Connected — Auto-sync off"
        case .syncing: return "Syncing changes..."
        case .searching: return "Searching for display..."
        case .error: return "Connection lost"
        case .disconnected: return "Not connected"
        }
    }

    private func testConnection() {
        connectionStatus = .testing
        Task {
            let (success, message) = await pushService.testConnection(store: store, bleManager: bleManager)
            withAnimation { connectionStatus = success ? .success : .failure(message) }
            if success {
                connectionManager.connectionState = .connected
                connectionManager.discoveredHost = store.pushTarget.baseUrl
            }
        }
    }
}

private extension TransportMode {
    var accentColor: Color {
        switch self {
        case .wifi: return .blue
        case .bluetooth: return .indigo
        case .auto: return .purple
        }
    }
}

struct BLEScanSheet: View {
    let bleManager: BLEManager
    let store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if bleManager.discoveredDevices.isEmpty {
                    emptyState
                } else {
                    deviceList
                }
            }
            .navigationTitle("Nearby Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if bleManager.connectionState == .scanning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(String(format: "%.0fs", bleManager.scanDuration))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            ZStack {
                if bleManager.connectionState == .scanning {
                    RadarScanView(color: .blue)
                        .frame(width: 120, height: 120)
                }

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 140)

            VStack(spacing: 8) {
                Text(bleManager.connectionState == .scanning ? "Scanning..." : "No Devices Found")
                    .font(.title3.weight(.semibold))

                Text("Make sure your Masjid Display device is powered on and in range.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if bleManager.connectionState != .scanning {
                Button {
                    bleManager.start(targetName: store.pushTarget.bleDeviceName)
                    bleManager.startScanning()
                } label: {
                    Label("Start Scanning", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DS.Spacing.xl)
    }

    private var deviceList: some View {
        List {
            let masjidDevices = bleManager.discoveredDevices.filter(\.isMasjidDevice)
            let otherDevices = bleManager.discoveredDevices.filter { !$0.isMasjidDevice }

            if !masjidDevices.isEmpty {
                Section {
                    ForEach(masjidDevices) { device in
                        deviceRow(device: device, highlight: true)
                    }
                } header: {
                    Label("Masjid Displays", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            if !otherDevices.isEmpty {
                Section {
                    ForEach(otherDevices) { device in
                        deviceRow(device: device, highlight: false)
                    }
                } header: {
                    Text("Other Devices (\(otherDevices.count))")
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private func deviceRow(device: DiscoveredDevice, highlight: Bool) -> some View {
        Button {
            bleManager.connect(to: device)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(highlight ? .green.opacity(0.12) : .blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: highlight ? "checkmark.seal.fill" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16))
                        .foregroundStyle(highlight ? .green : .blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(String(device.id.uuidString.prefix(8)))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(device.rssi) dBm")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                SignalStrengthView(rssi: device.rssi, color: highlight ? .green : .blue)

                if bleManager.connectedPeripheral?.identifier == device.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
