import SwiftUI
import SwiftUIX

struct SettingsView: View {
    @Bindable var store: AppStore
    @Bindable var connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.md) {
                connectionStatusBar
                timeFormatSection
                locationSection
                calculationSection
                iqamaSection
                jumuahSection
                tickerSection
                dateDisplaySection
                displaySection
                brightnessSection
                securitySection
                advancedSection
                dataSection
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: .cyan, showGlow: false) { Color.clear })
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.about) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .onChange(of: store.location) { _, _ in
            store.regenerateSchedule()
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
        .onChange(of: store.iqama) { _, _ in
            store.regenerateSchedule()
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
        .onChange(of: store.jumuah) { _, _ in
            store.regenerateSchedule()
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
        .onChange(of: store.timeFormat) { _, _ in
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
        .onChange(of: store.display.brightness) { _, _ in
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
        .onChange(of: store.largeMode) { _, _ in
            store.save()
            connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
        }
    }

    private var timeFormatSection: some View {
        DSSection("Time Format", icon: "clock.fill", color: .cyan) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    Text("Display Format")
                        .font(.subheadline)
                    Spacer()
                    Picker("Format", selection: $store.timeFormat) {
                        ForEach(TimeFormat.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                Text("Controls how prayer times appear on the display clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var locationSection: some View {
        DSSection("Location", icon: "location.fill", color: .blue) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    Text("City").font(.subheadline)
                    Spacer()
                    Picker("City", selection: Binding(
                        get: { store.location.cityName },
                        set: { name in
                            if let preset = LocationConfig.presets.first(where: { $0.cityName == name }) {
                                store.location = preset
                            }
                        }
                    )) {
                        ForEach(LocationConfig.presets, id: \.cityName) { preset in
                            Text(preset.cityName).tag(preset.cityName)
                        }
                    }
                    .tint(.secondary)
                }
                settingsRow("Timezone", value: store.location.timezone)
                settingsRow("Latitude", value: String(format: "%.4f", store.location.lat))
                settingsRow("Longitude", value: String(format: "%.4f", store.location.lng))
            }
        }
    }

    private var calculationSection: some View {
        DSSection("Calculation", icon: "function", color: .purple) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    Text("Method").font(.subheadline)
                    Spacer()
                    Picker("Method", selection: $store.calculation.method) {
                        ForEach(CalculationMethod.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .tint(.secondary)
                }
                HStack {
                    Text("Madhab").font(.subheadline)
                    Spacer()
                    Picker("Madhab", selection: $store.calculation.madhab) {
                        ForEach(Madhab.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .tint(.secondary)
                }
            }
        }
    }

    private var iqamaSection: some View {
        DSSection("Iqama", icon: "bell.fill", color: .orange) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("Enable Iqama", isOn: $store.iqama.enabled)
                    .font(.subheadline).tint(.orange)
                if store.iqama.enabled {
                    iqamaStepper("Fajr", value: $store.iqama.iqamaMinutes.fajr, range: 5...60)
                    iqamaStepper("Dhuhr", value: $store.iqama.iqamaMinutes.dhuhr, range: 5...60)
                    iqamaStepper("Asr", value: $store.iqama.iqamaMinutes.asr, range: 5...60)
                    iqamaStepper("Maghrib", value: $store.iqama.iqamaMinutes.maghrib, range: 3...30)
                    iqamaStepper("Isha", value: $store.iqama.iqamaMinutes.isha, range: 5...60)
                }
            }
        }
    }

    private var jumuahSection: some View {
        DSSection("Jumu'ah (Friday)", icon: "building.columns.fill", color: .green) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("Enable Jumu'ah Mode", isOn: $store.jumuah.enabled)
                    .font(.subheadline).tint(.green)
                if store.jumuah.enabled {
                    HStack {
                        Text("Jumu'ah Time").font(.subheadline)
                        Spacer()
                        TextField("HH:mm", text: $store.jumuah.jumuahTime)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numbersAndPunctuation)
                            .frame(width: 80)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    Stepper("Iqama: \(store.jumuah.jumuahIqamaMinutes) min", value: $store.jumuah.jumuahIqamaMinutes, in: 5...60, step: 5)
                        .font(.subheadline)
                    Toggle("Second Jumu'ah", isOn: $store.jumuah.secondJumuahEnabled)
                        .font(.subheadline).tint(.green)
                    if store.jumuah.secondJumuahEnabled {
                        HStack {
                            Text("Second Time").font(.subheadline)
                            Spacer()
                            TextField("HH:mm", text: $store.jumuah.secondJumuahTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .frame(width: 80)
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    private var tickerSection: some View {
        DSSection("Ticker / Messages", icon: "text.line.first.and.arrowtriangle.forward", color: .teal) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("Show Ticker", isOn: $store.display.showDhikrTicker)
                    .font(.subheadline).tint(.teal)

                if store.display.showDhikrTicker {
                    HStack {
                        Text("Mode").font(.subheadline)
                        Spacer()
                        Picker("Mode", selection: $store.ticker.mode) {
                            ForEach(TickerMode.allCases, id: \.self) { m in
                                Label(m.displayName, systemImage: m.icon).tag(m)
                            }
                        }
                        .tint(.secondary)
                    }

                    if store.ticker.mode == .custom {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Message")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            TextField("اكتب رسالتك هنا...", text: $store.ticker.customMessage, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                                .environment(\.layoutDirection, .rightToLeft)

                            Button {
                                Task {
                                    await connectionManager.sendTickerMessage(
                                        message: store.ticker.customMessage,
                                        store: store
                                    )
                                }
                            } label: {
                                Label("Broadcast Now", systemImage: "paperplane.fill")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.teal)
                            .controlSize(.small)
                            .disabled(store.ticker.customMessage.isEmpty)
                        }
                    }

                    if store.ticker.mode == .announcements {
                        announcementsEditor
                    }

                    HStack {
                        Text("Direction").font(.subheadline)
                        Spacer()
                        Picker("Direction", selection: $store.display.tickerDirection) {
                            ForEach(TickerDirection.allCases, id: \.self) { d in
                                Text(d.displayName).tag(d)
                            }
                        }
                        .tint(.secondary)
                    }

                    Stepper("Rotate every \(store.ticker.rotationIntervalMinutes) min", value: $store.ticker.rotationIntervalMinutes, in: 1...30)
                        .font(.subheadline)

                    Toggle("Pause During Adhan/Iqama", isOn: $store.ticker.pauseDuringAdhan)
                        .font(.subheadline).tint(.teal)
                }
            }
        }
    }

    private var announcementsEditor: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Announcements")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            ForEach(store.ticker.announcements) { announcement in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(announcement.text)
                            .font(.subheadline)
                            .lineLimit(2)
                        if announcement.isPinned {
                            Label("Pinned", systemImage: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if let exp = announcement.expiresAt {
                            Text("Expires: \(exp, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        store.ticker.announcements.removeAll { $0.id == announcement.id }
                        store.save()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(DS.Spacing.sm)
                .background(.white.opacity(0.05))
                .clipShape(.rect(cornerRadius: DS.Radius.sm))
            }

            AddAnnouncementRow(onAdd: { text, pinned, expDate in
                let ann = AnnouncementMessage(text: text, expiresAt: expDate, isPinned: pinned)
                store.ticker.announcements.append(ann)
                store.save()
                connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
            })
        }
    }

    private var dateDisplaySection: some View {
        DSSection("Date Display", icon: "calendar", color: .red) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("Show Gregorian", isOn: $store.dateDisplay.showGregorian)
                    .font(.subheadline).tint(.cyan)
                Toggle("Show Hijri", isOn: $store.dateDisplay.showHijri)
                    .font(.subheadline).tint(.cyan)
                Toggle("Arabic Weekday", isOn: $store.dateDisplay.showWeekdayArabic)
                    .font(.subheadline).tint(.cyan)
                Toggle("English Weekday", isOn: $store.dateDisplay.showWeekdayEnglish)
                    .font(.subheadline).tint(.cyan)
            }
        }
    }

    private var displaySection: some View {
        DSSection("Display", icon: "tv.fill", color: .indigo) {
            VStack(spacing: DS.Spacing.sm) {
                HStack {
                    Text("Language").font(.subheadline)
                    Spacer()
                    Picker("Language", selection: $store.display.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { l in
                            Text(l.displayName).tag(l)
                        }
                    }
                    .tint(.secondary)
                }

                HStack {
                    Text("Layout").font(.subheadline)
                    Spacer()
                    Picker("Layout", selection: $store.display.layout) {
                        ForEach(LayoutPreset.allCases, id: \.self) { l in
                            Text(l.displayName).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                Toggle("Lock Layout", isOn: $store.display.lockLayout)
                    .font(.subheadline).tint(.cyan)

                Toggle("Large Mode (Bigger Fonts)", isOn: $store.largeMode)
                    .font(.subheadline).tint(.cyan)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Brightness").font(.subheadline)
                        Spacer()
                        Text("\(store.display.brightness)%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(store.display.brightness) },
                        set: { store.display.brightness = Int($0) }
                    ), in: 10...100, step: 5)
                    .tint(.cyan)
                }
            }
        }
    }

    private var brightnessSection: some View {
        DSSection("Brightness Schedule", icon: "sun.max.fill", color: .yellow) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("Auto Brightness", isOn: $store.brightnessSchedule.enabled)
                    .font(.subheadline).tint(.yellow)
                if store.brightnessSchedule.enabled {
                    Stepper("Day: \(store.brightnessSchedule.dayBrightness)%", value: $store.brightnessSchedule.dayBrightness, in: 20...100, step: 10)
                        .font(.subheadline)
                    Stepper("Night: \(store.brightnessSchedule.nightBrightness)%", value: $store.brightnessSchedule.nightBrightness, in: 10...80, step: 10)
                        .font(.subheadline)
                    Stepper("Day starts: \(store.brightnessSchedule.dayStartHour):00", value: $store.brightnessSchedule.dayStartHour, in: 4...10)
                        .font(.subheadline)
                    Stepper("Night starts: \(store.brightnessSchedule.nightStartHour):00", value: $store.brightnessSchedule.nightStartHour, in: 18...23)
                        .font(.subheadline)
                }
            }
        }
    }

    private var securitySection: some View {
        DSSection("Security", icon: "lock.shield.fill", color: .red) {
            VStack(spacing: DS.Spacing.sm) {
                Toggle("HMAC Signature", isOn: $store.pushTarget.useHMAC)
                    .font(.subheadline).tint(.red)
                if store.pushTarget.useHMAC {
                    HStack {
                        Text("HMAC Secret").font(.subheadline)
                        Spacer()
                        SecureField("Secret", text: $store.pushTarget.hmacSecret)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var advancedSection: some View {
        DSSection("Advanced", icon: "gearshape.2.fill", color: .gray) {
            VStack(spacing: DS.Spacing.sm) {
                Stepper("Adhan Duration: \(store.advanced.adhanActiveSeconds)s", value: $store.advanced.adhanActiveSeconds, in: 30...300, step: 30)
                    .font(.subheadline)
                Stepper("Prayer Duration: \(store.advanced.prayerInProgressMinutes) min", value: $store.advanced.prayerInProgressMinutes, in: 5...30)
                    .font(.subheadline)
                settingsRow("Schedule Mode", value: store.advanced.scheduleMode == "simulated" ? "Manual / Simulated" : store.advanced.scheduleMode)
                HStack {
                    Text("Pi URL").font(.subheadline)
                    Spacer()
                    TextField("URL", text: $store.pushTarget.baseUrl)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                HStack {
                    Text("API Key").font(.subheadline)
                    Spacer()
                    TextField("Key", text: $store.pushTarget.apiKey)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                Toggle("Auto-Sync", isOn: $connectionManager.isAutoSyncEnabled)
                    .font(.subheadline).tint(.cyan)
                Text("Automatically push changes when connected to the display")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataSection: some View {
        DSCard(glow: .cyan) {
            VStack(spacing: DS.Spacing.sm) {
                SectionHeader(title: "Data", icon: "externaldrive.fill", color: .cyan)

                Button {
                    exportConfig()
                } label: {
                    HStack {
                        Label("Export Config (JSON)", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    store.save()
                    connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
                    toastManager?.show(.success, message: "Settings saved & synced")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: store.saveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                            .foregroundStyle(store.saveConfirmation ? .green : .cyan)
                        Text(store.saveConfirmation ? "Saved!" : "Save All Settings")
                            .font(.headline)
                            .foregroundStyle(store.saveConfirmation ? .green : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: store.saveConfirmation ? [.green.opacity(0.15), .green.opacity(0.05)] : [.cyan.opacity(0.15), .cyan.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: DS.Radius.md))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: store.saveConfirmation)
            }
        }
    }

    @ViewBuilder
    private var connectionStatusBar: some View {
        let isError = connectionManager.connectionState == .error
        DSCard(glow: syncStateColor) {
            VStack(spacing: 0) {
                ConnectionStatusOrnament(
                    state: connectionManager.connectionState,
                    isPaired: connectionManager.isPaired,
                    pendingCount: connectionManager.pendingCount,
                    pingMs: connectionManager.serverResponseTimeMs
                )

                if connectionManager.connectionState == .error || connectionManager.connectionState == .disconnected {
                    Divider().opacity(0.3)
                    HStack {
                        Spacer(minLength: 0)
                        Button {
                            Task {
                                await connectionManager.tryConnect(store: store)
                                if connectionManager.connectionState == .connected {
                                    toastManager?.show(.success, message: "Connected to display")
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                        .tint(.cyan)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.sm)
                }
            }
        }
        .focusRing(isActive: isError, color: .red)
    }

    private var syncStateColor: Color {
        switch connectionManager.connectionState {
        case .connected: return .green
        case .syncing: return .cyan
        case .searching: return .orange
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func iqamaStepper(_ prayer: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(prayer)
                .font(.subheadline)
                .frame(width: 70, alignment: .leading)
            Spacer()
            HStack(spacing: DS.Spacing.xs) {
                Button {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= (prayer == "Maghrib" ? 1 : 5)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text("\(value.wrappedValue) min")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .frame(width: 56)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 6))

                Button {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += (prayer == "Maghrib" ? 1 : 5)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exportConfig() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let state = PersistentState(
            location: store.location,
            calculation: store.calculation,
            iqama: store.iqama,
            jumuah: store.jumuah,
            dateDisplay: store.dateDisplay,
            display: store.display,
            brightnessSchedule: store.brightnessSchedule,
            selectedTheme: store.selectedTheme,
            pushTarget: store.pushTarget,
            advanced: store.advanced,
            hasCompletedSetup: store.hasCompletedSetup,
            timeFormat: store.timeFormat,
            ticker: store.ticker,
            themeCustomizations: store.themeCustomizations,
            largeMode: store.largeMode,
            faceConfig: store.faceConfig
        )
        guard let data = try? encoder.encode(state),
              let json = String(data: data, encoding: .utf8) else { return }

        let av = UIActivityViewController(activityItems: [json], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = scene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }
}
