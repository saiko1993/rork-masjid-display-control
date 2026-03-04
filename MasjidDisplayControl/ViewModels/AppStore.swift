import SwiftUI

@Observable
@MainActor
class AppStore {
    var location: LocationConfig = .cairo
    var calculation: CalculationConfig = .default
    var iqama: IqamaConfig = .default
    var jumuah: JumuahConfig = .default
    var dateDisplay: DateDisplayConfig = .default
    var display: DisplayConfig = .default
    var brightnessSchedule: BrightnessSchedule = .default
    var selectedTheme: ThemeId = .islamicGeoDark
    var pushTarget: PushTarget = .default
    var advanced: AdvancedConfig = .default
    var hasCompletedSetup: Bool = false
    var prayerSchedule: [PrayerTime] = []
    var simulatedTime: Date? = nil
    var demoMode: Bool = false

    var timeFormat: TimeFormat = .twentyFour
    var ticker: TickerConfig = .default
    var themeCustomizations: ThemeCustomizationStore = .empty
    var saveConfirmation: Bool = false
    var largeMode: Bool = false
    var faceConfig: FaceConfiguration = .default
    var activeProfile: SettingsProfile = .normal
    var audio: AudioConfig = .default
    var power: PowerConfig = .default
    var ramadanConfig: RamadanConfig = .default
    var quranProgram: QuranProgramConfig = .default
    var prayerEnabled: PrayerEnabled = .allEnabled
    var backgroundConfig: BackgroundConfig = .default

    private var saveTask: Task<Void, Never>? = nil
    private var confirmationTask: Task<Void, Never>? = nil

    var currentTheme: ThemeDefinition {
        let base = ThemeDefinition.theme(for: selectedTheme)
        let override = themeCustomizations.override(for: selectedTheme)
        return override.hasOverrides ? base.applying(override: override) : base
    }

    var baseTheme: ThemeDefinition {
        ThemeDefinition.theme(for: selectedTheme)
    }

    var effectiveNow: Date {
        simulatedTime ?? Date()
    }

    var stateInfo: PrayerStateInfo {
        PrayerStateMachine.evaluate(
            now: effectiveNow,
            schedule: prayerSchedule,
            adhanActiveSeconds: advanced.adhanActiveSeconds,
            iqamaConfig: iqama,
            prayerInProgressMinutes: advanced.prayerInProgressMinutes
        )
    }

    var currentOverride: ThemeColorOverride {
        get { themeCustomizations.override(for: selectedTheme) }
        set { themeCustomizations.setOverride(newValue, for: selectedTheme) }
    }

    init() {
        load()
        regenerateSchedule()
    }

    func regenerateSchedule() {
        prayerSchedule = ScheduleSimulator.generateSchedule(
            for: location,
            date: Date(),
            iqamaConfig: iqama,
            jumuahConfig: jumuah
        )
    }

    func startDemoMode() {
        demoMode = true
        guard let firstPrayer = prayerSchedule.first else { return }
        simulatedTime = firstPrayer.time.addingTimeInterval(-5)
    }

    func stopDemoMode() {
        demoMode = false
        simulatedTime = nil
    }

    func advanceDemoPhase() {
        guard demoMode, let current = simulatedTime else { return }
        let state = PrayerStateMachine.evaluate(
            now: current,
            schedule: prayerSchedule,
            adhanActiveSeconds: advanced.adhanActiveSeconds,
            iqamaConfig: iqama,
            prayerInProgressMinutes: advanced.prayerInProgressMinutes
        )

        switch state.phase {
        case .normal:
            if let nextTime = state.nextPrayerTime {
                simulatedTime = nextTime
            }
        case .adhanActive:
            simulatedTime = current.addingTimeInterval(Double(state.adhanRemainingSeconds) + 1)
        case .iqamaCountdown:
            simulatedTime = current.addingTimeInterval(Double(state.iqamaCountdownSeconds) + 1)
        case .prayerInProgress:
            simulatedTime = current.addingTimeInterval(Double(state.countdownSeconds) + 1)
        }
    }

    func resetThemeOverride() {
        themeCustomizations.resetOverride(for: selectedTheme)
        save()
    }

    func duplicateThemeOverride(from sourceId: ThemeId, to targetId: ThemeId) {
        let source = themeCustomizations.override(for: sourceId)
        themeCustomizations.setOverride(source, for: targetId)
        save()
    }

    func save() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            performSave()
        }
    }

    func saveImmediate() {
        saveTask?.cancel()
        performSave()
    }

    private func performSave() {
        let state = PersistentState(
            schemaVersion: PersistentState.currentSchemaVersion,
            location: location,
            calculation: calculation,
            iqama: iqama,
            jumuah: jumuah,
            dateDisplay: dateDisplay,
            display: display,
            brightnessSchedule: brightnessSchedule,
            selectedTheme: selectedTheme,
            pushTarget: pushTarget,
            advanced: advanced,
            hasCompletedSetup: hasCompletedSetup,
            timeFormat: timeFormat,
            ticker: ticker,
            themeCustomizations: themeCustomizations,
            largeMode: largeMode,
            faceConfig: faceConfig,
            activeProfile: activeProfile,
            audio: audio,
            power: power,
            ramadanConfig: ramadanConfig,
            quranProgram: quranProgram,
            prayerEnabled: prayerEnabled,
            backgroundConfig: backgroundConfig
        )
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(state) {
            UserDefaults.standard.set(data, forKey: "appStore")
        }
        saveConfirmation = true
        confirmationTask?.cancel()
        confirmationTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            saveConfirmation = false
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: "appStore"),
              let state = try? JSONDecoder().decode(PersistentState.self, from: data) else { return }
        location = state.location
        calculation = state.calculation
        iqama = state.iqama
        jumuah = state.jumuah ?? .default
        dateDisplay = state.dateDisplay
        display = state.display
        brightnessSchedule = state.brightnessSchedule ?? .default
        selectedTheme = state.selectedTheme
        pushTarget = state.pushTarget
        advanced = state.advanced
        hasCompletedSetup = state.hasCompletedSetup
        timeFormat = state.timeFormat ?? .twentyFour
        ticker = state.ticker ?? .default
        themeCustomizations = state.themeCustomizations ?? .empty
        largeMode = state.largeMode ?? false
        faceConfig = state.faceConfig ?? .default
        activeProfile = state.activeProfile ?? .normal
        audio = state.audio ?? .default
        power = state.power ?? .default
        ramadanConfig = state.ramadanConfig ?? .default
        quranProgram = state.quranProgram ?? .default
        prayerEnabled = state.prayerEnabled ?? .allEnabled
        backgroundConfig = state.backgroundConfig ?? .default
    }
}

nonisolated struct PersistentState: Codable, Sendable {
    let schemaVersion: Int?
    let location: LocationConfig
    let calculation: CalculationConfig
    let iqama: IqamaConfig
    let jumuah: JumuahConfig?
    let dateDisplay: DateDisplayConfig
    let display: DisplayConfig
    let brightnessSchedule: BrightnessSchedule?
    let selectedTheme: ThemeId
    let pushTarget: PushTarget
    let advanced: AdvancedConfig
    let hasCompletedSetup: Bool
    let timeFormat: TimeFormat?
    let ticker: TickerConfig?
    let themeCustomizations: ThemeCustomizationStore?
    let largeMode: Bool?
    let faceConfig: FaceConfiguration?
    let activeProfile: SettingsProfile?
    let audio: AudioConfig?
    let power: PowerConfig?
    let ramadanConfig: RamadanConfig?
    let quranProgram: QuranProgramConfig?
    let prayerEnabled: PrayerEnabled?
    let backgroundConfig: BackgroundConfig?

    static let currentSchemaVersion = 1
}
