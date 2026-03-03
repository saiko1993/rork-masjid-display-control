import Foundation
import SwiftUI

nonisolated struct ThemePackPayload: Codable, Sendable {
    let version: String
    let pushId: String
    let sentAtISO: String
    let themeId: String
    let nameAr: String
    let nameEn: String
    let isDark: Bool
    let contrastRatio: Double
    let palette: ThemePalettePayload
    let typography: ThemeTypographyPayload
    let tokens: ThemeTokensPayload
    let backgroundPattern: String
    let layerStack: LayerStackPayload
    let customOverrides: CustomOverridesPayload?
    let face: FacePayload?
}

nonisolated struct ThemePalettePayload: Codable, Sendable {
    let background: String
    let surface: String
    let primary: String
    let secondary: String
    let textPrimary: String
    let textSecondary: String
    let accent: String
    let adhanGlow: String
}

nonisolated struct ThemeTypographyPayload: Codable, Sendable {
    let timeFontDesign: String
    let arabicFontDesign: String
    let latinFontDesign: String
    let timeWeight: String
    let headingWeight: String
}

nonisolated struct ThemeTokensPayload: Codable, Sendable {
    let cornerRadius: Double
    let cardPadding: Double
    let sectionSpacing: Double
    let borderWidth: Double
    let shadowRadius: Double
    let minReadableFontSize: Double
    let safeMargins: Double
    let tableDensity: String
    let tickerDirection: String
    let minFontScale: Double
    let maxFontScale: Double
}

nonisolated struct LayerStackPayload: Codable, Sendable {
    let backgroundBase: String
    let gradientStops: [GradientStopPayload]
    let gradientAngle: Double
    let patternType: String
    let patternColor: String
    let patternOpacity: Double
    let vignetteType: String
    let vignetteIntensity: Double
    let elevationStyle: String
    let cardBorderColor: String?
    let cardBorderOpacity: Double
    let hasShimmer: Bool
    let shimmerSpeed: Double
    let adhanGlowStyle: String
    let adhanGlowColor: String
    let countdownGlowRadius: Double
    let tableRowSeparator: Bool
    let tableRowInset: Bool
    let tickerBackground: String?
    let backgroundImageUrl: String?
    let backgroundImageFit: String?
}

nonisolated struct GradientStopPayload: Codable, Sendable {
    let color: String
    let location: Double
}

nonisolated struct CustomOverridesPayload: Codable, Sendable {
    let backgroundHex: String?
    let surfaceHex: String?
    let primaryHex: String?
    let secondaryHex: String?
    let textPrimaryHex: String?
    let textSecondaryHex: String?
    let accentHex: String?
    let patternOpacity: Double?
    let vignetteIntensity: Double?
    let backgroundImageUrl: String?
}

nonisolated struct LightSyncPayload: Codable, Sendable {
    let version: String
    let pushId: String
    let sentAtISO: String
    let nowEpoch: Int
    let deviceTime: String
    let tz: String
    let tzOffsetMinutes: Int
    let schedule: [ScheduleEntry]
    let currentPhase: PhasePayload?
    let display: DisplaySyncPayload
    let brightnessSchedule: BrightnessSyncPayload
    let calculation: CalculationSyncPayload?
    let iqama: IqamaSyncPayload?
    let jumuah: JumuahSyncPayload?
    let location: LocationSyncPayload
    let timeFormat: String
    let ticker: TickerSyncPayload?
    let largeMode: Bool
    let faceId: String?
    let audio: AudioSyncPayload?
    let dateConfig: DateSyncPayload?
    let power: PowerSyncPayload?
    let ramadan: RamadanSyncPayload?
    let quranProgram: QuranProgramSyncPayload?
    let prayerEnabled: [String: Bool]?
    let activeProfile: String?
}

nonisolated struct ScheduleEntry: Codable, Sendable {
    let prayer: String
    let adhan: String
    let adhanISO: String
    let iqama: String?
    let iqamaISO: String?
    let isJumuah: Bool
}

nonisolated struct PhasePayload: Codable, Sendable {
    let phase: String
    let currentPrayer: String?
    let nextPrayer: String?
}

nonisolated struct DisplaySyncPayload: Codable, Sendable {
    let language: String
    let brightness: Int
    let layout: String
    let showDhikrTicker: Bool
    let tickerDirection: String
    let pauseTickerDuringAdhan: Bool
    let lockLayout: Bool
}

nonisolated struct BrightnessSyncPayload: Codable, Sendable {
    let enabled: Bool
    let dayBrightness: Int
    let nightBrightness: Int
    let dayStartHour: Int
    let nightStartHour: Int
}

nonisolated struct CalculationSyncPayload: Codable, Sendable {
    let method: String
    let madhab: String
    let offsetsMinutes: [String: Int]
}

nonisolated struct IqamaSyncPayload: Codable, Sendable {
    let enabled: Bool
    let mode: String
    let minutes: [String: Int]
    let iqamaMode: String?
    let fixedTimes: [String: String]?
}

nonisolated struct JumuahSyncPayload: Codable, Sendable {
    let enabled: Bool
    let jumuahTime: String
    let jumuahIqamaMinutes: Int
    let secondJumuahEnabled: Bool
    let secondJumuahTime: String
}

nonisolated struct LocationSyncPayload: Codable, Sendable {
    let cityName: String
    let lat: Double
    let lng: Double
    let timezone: String
}

nonisolated struct TickerSyncPayload: Codable, Sendable {
    let mode: String
    let customMessage: String
    let pauseDuringAdhan: Bool
    let announcements: [AnnouncementSyncPayload]?
    let rotationIntervalMinutes: Int
}

nonisolated struct AnnouncementSyncPayload: Codable, Sendable {
    let id: String
    let text: String
    let isPinned: Bool
}

nonisolated struct AudioSyncPayload: Codable, Sendable {
    let adhanMode: String
    let globalVolume: Int
    let perPrayerVolume: [String: Int]?
    let preAdhanReminderMinutes: Int
    let reminderSoundType: String
}

nonisolated struct DateSyncPayload: Codable, Sendable {
    let displayMode: String
    let hijriOffsetDays: Int
    let showGregorian: Bool
    let showHijri: Bool
    let showWeekdayArabic: Bool
    let showWeekdayEnglish: Bool
}

nonisolated struct PowerSyncPayload: Codable, Sendable {
    let screenOffEnabled: Bool
    let screenOffFromHour: Int
    let screenOffToHour: Int
    let autoWakeBeforeFajrMinutes: Int
}

nonisolated struct RamadanSyncPayload: Codable, Sendable {
    let ishaMode: String
    let ishaAfterMaghribMinutes: Int
    let ishaFixedTime: String
    let autoDetect: Bool
    let isCurrentlyRamadan: Bool
}

nonisolated struct QuranProgramSyncPayload: Codable, Sendable {
    let enabled: Bool
    let khatmaMode: String
    let playbackMode: String
    let reciterId: String
    let reciterName: String
    let dailyStartTime: String
    let currentDay: Int
}

struct PayloadBuilder {
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let time12Formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    private static let isoFormatter = ISO8601DateFormatter()

    static func buildThemePack(from store: AppStore) -> ThemePackPayload {
        let theme = store.currentTheme
        let override = store.currentOverride
        let now = Date()

        return ThemePackPayload(
            version: "3.0.0",
            pushId: UUID().uuidString,
            sentAtISO: isoFormatter.string(from: now),
            themeId: theme.id.rawValue,
            nameAr: theme.nameAr,
            nameEn: theme.nameEn,
            isDark: theme.isDark,
            contrastRatio: theme.contrastRatio,
            palette: ThemePalettePayload(
                background: colorToHex(theme.palette.background),
                surface: colorToHex(theme.palette.surface),
                primary: colorToHex(theme.palette.primary),
                secondary: colorToHex(theme.palette.secondary),
                textPrimary: colorToHex(theme.palette.textPrimary),
                textSecondary: colorToHex(theme.palette.textSecondary),
                accent: colorToHex(theme.palette.accent),
                adhanGlow: colorToHex(theme.palette.adhanGlow)
            ),
            typography: ThemeTypographyPayload(
                timeFontDesign: fontDesignString(theme.typography.timeFontDesign),
                arabicFontDesign: fontDesignString(theme.typography.arabicFontDesign),
                latinFontDesign: fontDesignString(theme.typography.latinFontDesign),
                timeWeight: fontWeightString(theme.typography.timeWeight),
                headingWeight: fontWeightString(theme.typography.headingWeight)
            ),
            tokens: ThemeTokensPayload(
                cornerRadius: Double(theme.tokens.cornerRadius),
                cardPadding: Double(theme.tokens.cardPadding),
                sectionSpacing: Double(theme.tokens.sectionSpacing),
                borderWidth: Double(theme.tokens.borderWidth),
                shadowRadius: Double(theme.tokens.shadowRadius),
                minReadableFontSize: Double(theme.tokens.minReadableFontSize),
                safeMargins: Double(theme.tokens.safeMargins),
                tableDensity: theme.tokens.tableDensity.rawValue,
                tickerDirection: theme.tokens.tickerDirection.rawValue,
                minFontScale: Double(theme.tokens.minFontScale),
                maxFontScale: Double(theme.tokens.maxFontScale)
            ),
            backgroundPattern: patternString(theme.backgroundPattern),
            layerStack: LayerStackPayload(
                backgroundBase: colorToHex(theme.palette.background),
                gradientStops: theme.layers.gradientStops.map { GradientStopPayload(color: colorToHex($0.color), location: Double($0.location)) },
                gradientAngle: theme.layers.gradientAngle,
                patternType: patternString(theme.backgroundPattern),
                patternColor: colorToHex(theme.palette.primary),
                patternOpacity: Double(theme.layers.patternOpacity),
                vignetteType: vignetteString(theme.layers.vignetteStyle),
                vignetteIntensity: Double(theme.layers.vignetteIntensity),
                elevationStyle: elevationString(theme.layers.cardElevation),
                cardBorderColor: theme.layers.cardBorderColor.map { colorToHex($0) },
                cardBorderOpacity: Double(theme.layers.cardBorderOpacity),
                hasShimmer: theme.layers.hasShimmer,
                shimmerSpeed: theme.layers.shimmerSpeed,
                adhanGlowStyle: glowString(theme.layers.glowStyle),
                adhanGlowColor: colorToHex(theme.palette.adhanGlow),
                countdownGlowRadius: Double(theme.layers.countdownGlowRadius),
                tableRowSeparator: theme.layers.tableRowSeparator,
                tableRowInset: theme.layers.tableRowInset,
                tickerBackground: theme.layers.tickerBackground.map { colorToHex($0) },
                backgroundImageUrl: override.backgroundImageUrl,
                backgroundImageFit: override.backgroundImageFit
            ),
            customOverrides: override.hasOverrides ? CustomOverridesPayload(
                backgroundHex: override.backgroundHex,
                surfaceHex: override.surfaceHex,
                primaryHex: override.primaryHex,
                secondaryHex: override.secondaryHex,
                textPrimaryHex: override.textPrimaryHex,
                textSecondaryHex: override.textSecondaryHex,
                accentHex: override.accentHex,
                patternOpacity: override.patternOpacity,
                vignetteIntensity: override.vignetteIntensity,
                backgroundImageUrl: override.backgroundImageUrl
            ) : nil,
            face: FacePayload(
                faceId: store.faceConfig.faceId.rawValue,
                enabledComponents: store.faceConfig.enabledComponents.map { $0.rawValue }.sorted()
            )
        )
    }

    static func buildLightSync(from store: AppStore, includeConfig: Bool = true) -> LightSyncPayload {
        let now = Date()
        let tz = TimeZone(identifier: store.location.timezone) ?? .current
        let state = store.stateInfo
        let formatter = store.timeFormat == .twelve ? time12Formatter : timeFormatter

        let scheduleEntries: [ScheduleEntry] = store.prayerSchedule.map { pt in
            ScheduleEntry(
                prayer: pt.isJumuah ? "jumuah" : pt.prayer.rawValue,
                adhan: formatter.string(from: pt.time),
                adhanISO: isoFormatter.string(from: pt.time),
                iqama: pt.iqamaTime.map { formatter.string(from: $0) },
                iqamaISO: pt.iqamaTime.map { isoFormatter.string(from: $0) },
                isJumuah: pt.isJumuah
            )
        }

        let phase = PhasePayload(
            phase: state.phase.rawValue,
            currentPrayer: state.currentPrayer?.rawValue,
            nextPrayer: state.nextPrayer?.rawValue
        )

        let deviceTimeFormatter = DateFormatter()
        deviceTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        deviceTimeFormatter.timeZone = tz

        let iqamaPayload: IqamaSyncPayload? = includeConfig ? {
            var fixedTimesDict: [String: String]? = nil
            if let ft = store.iqama.fixedTimes, store.iqama.effectiveMode == .fixedTime {
                fixedTimesDict = [
                    "fajr": ft.fajr,
                    "dhuhr": ft.dhuhr,
                    "asr": ft.asr,
                    "maghrib": ft.maghrib,
                    "isha": ft.isha,
                ]
            }
            return IqamaSyncPayload(
                enabled: store.iqama.enabled,
                mode: store.iqama.effectiveMode.rawValue,
                minutes: [
                    "fajr": store.iqama.iqamaMinutes.fajr,
                    "dhuhr": store.iqama.iqamaMinutes.dhuhr,
                    "asr": store.iqama.iqamaMinutes.asr,
                    "maghrib": store.iqama.iqamaMinutes.maghrib,
                    "isha": store.iqama.iqamaMinutes.isha,
                ],
                iqamaMode: store.iqama.effectiveMode.rawValue,
                fixedTimes: fixedTimesDict
            )
        }() : nil

        let audioPayload: AudioSyncPayload? = includeConfig ? {
            var perPrayer: [String: Int]? = nil
            let pv = store.audio.perPrayerVolume
            if pv.hasOverrides {
                var dict: [String: Int] = [:]
                if let v = pv.fajr { dict["fajr"] = v }
                if let v = pv.dhuhr { dict["dhuhr"] = v }
                if let v = pv.asr { dict["asr"] = v }
                if let v = pv.maghrib { dict["maghrib"] = v }
                if let v = pv.isha { dict["isha"] = v }
                perPrayer = dict
            }
            return AudioSyncPayload(
                adhanMode: store.audio.adhanMode.rawValue,
                globalVolume: store.audio.globalVolume,
                perPrayerVolume: perPrayer,
                preAdhanReminderMinutes: store.audio.preAdhanReminderMinutes,
                reminderSoundType: store.audio.reminderSoundType.rawValue
            )
        }() : nil

        let datePayload: DateSyncPayload? = includeConfig ? DateSyncPayload(
            displayMode: store.dateDisplay.effectiveMode.rawValue,
            hijriOffsetDays: store.dateDisplay.effectiveHijriOffset,
            showGregorian: store.dateDisplay.showGregorian,
            showHijri: store.dateDisplay.showHijri,
            showWeekdayArabic: store.dateDisplay.showWeekdayArabic,
            showWeekdayEnglish: store.dateDisplay.showWeekdayEnglish
        ) : nil

        let powerPayload: PowerSyncPayload? = includeConfig ? PowerSyncPayload(
            screenOffEnabled: store.power.screenOffSchedule.enabled,
            screenOffFromHour: store.power.screenOffSchedule.fromHour,
            screenOffToHour: store.power.screenOffSchedule.toHour,
            autoWakeBeforeFajrMinutes: store.power.autoWakeBeforeFajrMinutes
        ) : nil

        let ramadanPayload: RamadanSyncPayload? = includeConfig ? RamadanSyncPayload(
            ishaMode: store.ramadanConfig.ishaMode.rawValue,
            ishaAfterMaghribMinutes: store.ramadanConfig.ishaAfterMaghribMinutes,
            ishaFixedTime: store.ramadanConfig.ishaFixedTime,
            autoDetect: store.ramadanConfig.autoDetect,
            isCurrentlyRamadan: RamadanConfig.isRamadan()
        ) : nil

        let quranPayload: QuranProgramSyncPayload? = includeConfig && store.quranProgram.enabled ? QuranProgramSyncPayload(
            enabled: store.quranProgram.enabled,
            khatmaMode: store.quranProgram.khatmaMode.rawValue,
            playbackMode: store.quranProgram.playbackMode.rawValue,
            reciterId: store.quranProgram.reciterId,
            reciterName: store.quranProgram.reciterName,
            dailyStartTime: store.quranProgram.dailyStartTime,
            currentDay: store.quranProgram.currentDay
        ) : nil

        let prayerEnabledDict: [String: Bool]? = includeConfig ? [
            "fajr": store.prayerEnabled.fajr,
            "dhuhr": store.prayerEnabled.dhuhr,
            "asr": store.prayerEnabled.asr,
            "maghrib": store.prayerEnabled.maghrib,
            "isha": store.prayerEnabled.isha,
        ] : nil

        return LightSyncPayload(
            version: "3.0.0",
            pushId: UUID().uuidString,
            sentAtISO: isoFormatter.string(from: now),
            nowEpoch: Int(now.timeIntervalSince1970),
            deviceTime: deviceTimeFormatter.string(from: now),
            tz: store.location.timezone,
            tzOffsetMinutes: tz.secondsFromGMT(for: now) / 60,
            schedule: scheduleEntries,
            currentPhase: phase,
            display: DisplaySyncPayload(
                language: store.display.language.rawValue,
                brightness: store.display.brightness,
                layout: store.display.layout.rawValue,
                showDhikrTicker: store.display.showDhikrTicker,
                tickerDirection: store.display.tickerDirection.rawValue,
                pauseTickerDuringAdhan: store.display.pauseTickerDuringAdhan,
                lockLayout: store.display.lockLayout
            ),
            brightnessSchedule: BrightnessSyncPayload(
                enabled: store.brightnessSchedule.enabled,
                dayBrightness: store.brightnessSchedule.dayBrightness,
                nightBrightness: store.brightnessSchedule.nightBrightness,
                dayStartHour: store.brightnessSchedule.dayStartHour,
                nightStartHour: store.brightnessSchedule.nightStartHour
            ),
            calculation: includeConfig ? CalculationSyncPayload(
                method: store.calculation.method.rawValue,
                madhab: store.calculation.madhab.rawValue,
                offsetsMinutes: [
                    "fajr": store.calculation.offsetsMinutes.fajr,
                    "dhuhr": store.calculation.offsetsMinutes.dhuhr,
                    "asr": store.calculation.offsetsMinutes.asr,
                    "maghrib": store.calculation.offsetsMinutes.maghrib,
                    "isha": store.calculation.offsetsMinutes.isha,
                ]
            ) : nil,
            iqama: iqamaPayload,
            jumuah: includeConfig ? JumuahSyncPayload(
                enabled: store.jumuah.enabled,
                jumuahTime: store.jumuah.jumuahTime,
                jumuahIqamaMinutes: store.jumuah.jumuahIqamaMinutes,
                secondJumuahEnabled: store.jumuah.secondJumuahEnabled,
                secondJumuahTime: store.jumuah.secondJumuahTime
            ) : nil,
            location: LocationSyncPayload(
                cityName: store.location.cityName,
                lat: store.location.lat,
                lng: store.location.lng,
                timezone: store.location.timezone
            ),
            timeFormat: store.timeFormat.rawValue,
            ticker: TickerSyncPayload(
                mode: store.ticker.mode.rawValue,
                customMessage: store.ticker.customMessage,
                pauseDuringAdhan: store.ticker.pauseDuringAdhan,
                announcements: store.ticker.announcements.isEmpty ? nil : store.ticker.announcements.compactMap { ann in
                    if let exp = ann.expiresAt, exp < Date() { return nil }
                    return AnnouncementSyncPayload(id: ann.id, text: ann.text, isPinned: ann.isPinned)
                },
                rotationIntervalMinutes: store.ticker.rotationIntervalMinutes
            ),
            largeMode: store.largeMode,
            faceId: store.faceConfig.faceId.rawValue,
            audio: audioPayload,
            dateConfig: datePayload,
            power: powerPayload,
            ramadan: ramadanPayload,
            quranProgram: quranPayload,
            prayerEnabled: prayerEnabledDict,
            activeProfile: store.activeProfile.rawValue
        )
    }

    static func toJSON<T: Encodable>(_ payload: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    static func encode<T: Encodable>(_ payload: T) -> Data? {
        try? JSONEncoder().encode(payload)
    }

    static func colorToHex(_ color: Color) -> String {
        let resolved = UIColor(color)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private static func fontDesignString(_ design: Font.Design) -> String {
        switch design {
        case .serif: return "serif"
        case .monospaced: return "monospaced"
        case .rounded: return "rounded"
        default: return "default"
        }
    }

    private static func fontWeightString(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold: return "bold"
        case .semibold: return "semibold"
        case .medium: return "medium"
        case .heavy: return "heavy"
        case .black: return "black"
        case .light: return "light"
        case .thin: return "thin"
        case .ultraLight: return "ultraLight"
        default: return "regular"
        }
    }

    static func patternString(_ pattern: BackgroundPattern) -> String {
        switch pattern {
        case .geometricStars: return "geometric_stars"
        case .arabesque: return "arabesque"
        case .minimal: return "minimal"
        case .none: return "none"
        case .reliefStarfield: return "relief_starfield"
        case .archMosaic: return "arch_mosaic"
        case .hexGrid: return "hex_grid"
        case .glassTile: return "glass_tile"
        case .ledMatrix: return "led_matrix"
        case .mosqueSilhouette: return "mosque_silhouette"
        }
    }

    static func vignetteString(_ style: VignetteStyle) -> String {
        switch style {
        case .none: return "none"
        case .radialDark: return "radial_dark"
        case .radialLight: return "radial_light"
        case .topFade: return "top_fade"
        case .bottomFade: return "bottom_fade"
        case .edgeBurn: return "edge_burn"
        }
    }

    static func elevationString(_ style: ElevationStyle) -> String {
        switch style {
        case .flat: return "flat"
        case .raised: return "raised"
        case .inset: return "inset"
        case .floating: return "floating"
        case .glassmorphic: return "glassmorphic"
        case .neumorphic: return "neumorphic"
        }
    }

    static func glowString(_ style: GlowStyle) -> String {
        switch style {
        case .pulse: return "pulse"
        case .radialBurst: return "radial_burst"
        case .borderGlow: return "border_glow"
        case .shimmerWave: return "shimmer_wave"
        case .neonFlicker: return "neon_flicker"
        case .softBreath: return "soft_breath"
        }
    }
}
