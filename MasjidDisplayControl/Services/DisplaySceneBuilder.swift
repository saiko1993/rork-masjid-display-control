import Foundation

struct DisplaySceneBuilder {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    static func build(
        store: AppStore,
        screenWidth: Int,
        screenHeight: Int,
        now: Date
    ) -> DisplayScene {
        let theme = store.currentTheme
        let rawScale = min(Double(screenWidth) / 1920.0, Double(screenHeight) / 1080.0)
        let scale = min(max(rawScale, Double(theme.tokens.minFontScale)), Double(theme.tokens.maxFontScale))
        let isCompact = screenWidth < 1000 || store.display.layout == .compactV1

        let state = PrayerStateMachine.evaluate(
            now: now,
            schedule: store.prayerSchedule,
            adhanActiveSeconds: store.advanced.adhanActiveSeconds,
            iqamaConfig: store.iqama,
            prayerInProgressMinutes: store.advanced.prayerInProgressMinutes
        )

        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: now)

        let shouldPauseTicker = store.display.pauseTickerDuringAdhan &&
            (state.phase == .adhanActive || state.phase == .iqamaCountdown || state.phase == .prayerInProgress)

        let highlightedPrayer: String? = {
            if state.phase == .normal, let next = state.nextPrayer { return next.rawValue }
            return nil
        }()

        let activePrayer: String? = {
            if state.phase != .normal, let current = state.currentPrayer { return current.rawValue }
            return nil
        }()

        let entries: [DisplayScene.PrayerEntry] = store.prayerSchedule.map { pt in
            DisplayScene.PrayerEntry(
                prayer: pt.prayer.rawValue,
                adhanTime: timeFormatter.string(from: pt.time),
                iqamaTime: pt.iqamaTime.map { timeFormatter.string(from: $0) },
                isJumuah: pt.isJumuah,
                nameAr: pt.isJumuah ? "الجمعة" : pt.prayer.displayNameAr,
                nameEn: pt.isJumuah ? "Jumu'ah" : pt.prayer.displayName,
                icon: pt.isJumuah ? "building.columns.fill" : pt.prayer.iconName
            )
        }

        return DisplayScene(
            version: "2.0.0",
            themeId: theme.id.rawValue,
            layout: store.display.layout.rawValue,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            scaleFactor: scale,
            isCompact: isCompact,
            clock: DisplayScene.ClockElement(
                hour: String(format: "%02d", comps.hour ?? 0),
                minute: String(format: "%02d", comps.minute ?? 0),
                second: String(format: "%02d", comps.second ?? 0)
            ),
            dateBlock: DisplayScene.DateBlockElement(
                arabicWeekday: store.dateDisplay.showWeekdayArabic ? HijriDateHelper.arabicWeekday(from: now) : nil,
                englishWeekday: store.dateDisplay.showWeekdayEnglish ? HijriDateHelper.englishWeekday(from: now) : nil,
                hijriDate: store.dateDisplay.showHijri ? HijriDateHelper.hijriString(from: now) : nil,
                gregorianDate: store.dateDisplay.showGregorian ? HijriDateHelper.gregorianString(from: now) : nil
            ),
            countdown: DisplayScene.CountdownElement(
                phase: state.phase.rawValue,
                currentPrayer: state.currentPrayer?.rawValue,
                nextPrayer: state.nextPrayer?.rawValue,
                label: state.phaseLabel,
                labelAr: state.phaseLabelAr,
                countdownSeconds: state.countdownSeconds,
                adhanRemainingSeconds: state.adhanRemainingSeconds,
                iqamaCountdownSeconds: state.iqamaCountdownSeconds,
                isJumuah: state.isJumuah
            ),
            prayerTable: DisplayScene.PrayerTableElement(
                entries: entries,
                highlightedPrayer: highlightedPrayer,
                activePrayer: activePrayer,
                language: store.display.language.rawValue,
                density: theme.tokens.tableDensity.rawValue
            ),
            ticker: DisplayScene.TickerElement(
                enabled: store.display.showDhikrTicker,
                isPaused: shouldPauseTicker,
                direction: store.display.tickerDirection.rawValue,
                phrases: DhikrData.phrases
            ),
            phaseOverlay: DisplayScene.PhaseOverlayElement(
                phase: state.phase.rawValue,
                showAdhanGlow: state.phase == .adhanActive,
                showDemoWatermark: store.demoMode
            ),
            footer: DisplayScene.FooterElement(
                cityName: store.location.cityName,
                isSimulated: store.advanced.scheduleMode == "simulated"
            )
        )
    }
}
