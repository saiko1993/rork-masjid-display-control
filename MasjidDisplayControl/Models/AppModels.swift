import SwiftUI

nonisolated enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case ar = "ar"
    case en = "en"

    var displayName: String {
        switch self {
        case .ar: return "العربية"
        case .en: return "English"
        }
    }
}

nonisolated enum CalculationMethod: String, Codable, CaseIterable, Sendable {
    case mwl = "MWL"
    case ummAlQura = "UmmAlQura"
    case isna = "ISNA"
    case egyptian = "Egyptian"
    case karachi = "Karachi"

    var displayName: String {
        switch self {
        case .mwl: return "Muslim World League"
        case .ummAlQura: return "Umm Al-Qura"
        case .isna: return "ISNA"
        case .egyptian: return "Egyptian"
        case .karachi: return "Karachi"
        }
    }

    var displayNameAr: String {
        switch self {
        case .mwl: return "رابطة العالم الإسلامي"
        case .ummAlQura: return "أم القرى"
        case .isna: return "أمريكا الشمالية"
        case .egyptian: return "الهيئة المصرية"
        case .karachi: return "كراتشي"
        }
    }
}

nonisolated enum Madhab: String, Codable, CaseIterable, Sendable {
    case shafi = "Shafi"
    case hanafi = "Hanafi"

    var displayName: String {
        switch self {
        case .shafi: return "Shafi'i"
        case .hanafi: return "Hanafi"
        }
    }
}

nonisolated enum LayoutPreset: String, Codable, CaseIterable, Sendable {
    case wideV1 = "wide-v1"
    case compactV1 = "compact-v1"

    var displayName: String {
        switch self {
        case .wideV1: return "Wide"
        case .compactV1: return "Compact"
        }
    }
}

nonisolated enum ThemeId: String, Codable, CaseIterable, Sendable {
    case islamicGeoDark = "islamic-geo-dark"
    case ottomanClassic = "ottoman-classic"
    case minimalNoor = "minimal-noor"
    case ledMosque = "led-mosque"
    case islamicRelief = "islamic-relief"
    case ottomanGoldNight = "ottoman-gold-night"
    case modernArchDepth = "modern-arch-depth"
    case smartGlass = "smart-glass"
    case ledDigitalPremium = "led-digital-premium"
    case skySilhouette = "sky-silhouette"

    var displayName: String {
        switch self {
        case .islamicGeoDark: return "Islamic Geometric Dark"
        case .ottomanClassic: return "Ottoman Classic"
        case .minimalNoor: return "Minimal Noor"
        case .ledMosque: return "LED Mosque"
        case .islamicRelief: return "Islamic Relief Layered"
        case .ottomanGoldNight: return "Ottoman Gold Night"
        case .modernArchDepth: return "Modern Architectural Depth"
        case .smartGlass: return "Smart Glass Mosque"
        case .ledDigitalPremium: return "LED Digital Premium"
        case .skySilhouette: return "Sky Silhouette Gradient"
        }
    }

    var displayNameAr: String {
        switch self {
        case .islamicGeoDark: return "هندسي إسلامي داكن"
        case .ottomanClassic: return "عثماني كلاسيكي"
        case .minimalNoor: return "نور بسيط"
        case .ledMosque: return "شاشة LED"
        case .islamicRelief: return "نقش إسلامي بارز"
        case .ottomanGoldNight: return "ليل عثماني ذهبي"
        case .modernArchDepth: return "عمق معماري حديث"
        case .smartGlass: return "زجاج ذكي"
        case .ledDigitalPremium: return "شاشة رقمية فاخرة"
        case .skySilhouette: return "ظلال السماء"
        }
    }
}

nonisolated enum Prayer: String, Codable, CaseIterable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha

    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        }
    }

    var displayNameAr: String {
        switch self {
        case .fajr: return "الفجر"
        case .dhuhr: return "الظهر"
        case .asr: return "العصر"
        case .maghrib: return "المغرب"
        case .isha: return "العشاء"
        }
    }

    var iconName: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

nonisolated enum PrayerPhase: String, Codable, Sendable {
    case normal
    case adhanActive = "adhan_active"
    case iqamaCountdown = "iqama_countdown"
    case prayerInProgress = "prayer_in_progress"
}

nonisolated enum TickerDirection: String, Codable, CaseIterable, Sendable {
    case ltr = "ltr"
    case rtl = "rtl"

    var displayName: String {
        switch self {
        case .ltr: return "Left → Right"
        case .rtl: return "Right → Left"
        }
    }
}

nonisolated enum TableDensity: String, Codable, CaseIterable, Sendable {
    case compact = "compact"
    case comfortable = "comfortable"

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .comfortable: return "Comfortable"
        }
    }
}

nonisolated enum TransportMode: String, Codable, CaseIterable, Sendable {
    case wifi = "wifi"
    case bluetooth = "bluetooth"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .wifi: return "WiFi"
        case .bluetooth: return "Bluetooth"
        case .auto: return "Auto"
        }
    }

    var displayNameAr: String {
        switch self {
        case .wifi: return "واي فاي"
        case .bluetooth: return "بلوتوث"
        case .auto: return "تلقائي"
        }
    }

    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .auto: return "arrow.triangle.branch"
        }
    }
}

nonisolated enum BLEConnectionState: String, Sendable {
    case disconnected
    case scanning
    case connecting
    case connected
    case ready
}

nonisolated enum PushResultStatus: String, Codable, Sendable {
    case success
    case failure
}

nonisolated enum PushType: String, Codable, Sendable {
    case themePack = "theme_pack"
    case lightSync = "light_sync"
    case testConnection = "test_connection"

    var displayName: String {
        switch self {
        case .themePack: return "Theme Pack"
        case .lightSync: return "Light Sync"
        case .testConnection: return "Test Connection"
        }
    }

    var icon: String {
        switch self {
        case .themePack: return "paintpalette.fill"
        case .lightSync: return "arrow.triangle.2.circlepath"
        case .testConnection: return "antenna.radiowaves.left.and.right"
        }
    }
}

nonisolated struct LocationConfig: Codable, Sendable, Hashable {
    var cityName: String
    var lat: Double
    var lng: Double
    var timezone: String

    static let cairo = LocationConfig(cityName: "Cairo", lat: 30.0444, lng: 31.2357, timezone: "Africa/Cairo")
    static let makkah = LocationConfig(cityName: "Makkah", lat: 21.4225, lng: 39.8262, timezone: "Asia/Riyadh")
    static let medina = LocationConfig(cityName: "Medina", lat: 24.4672, lng: 39.6112, timezone: "Asia/Riyadh")
    static let istanbul = LocationConfig(cityName: "Istanbul", lat: 41.0082, lng: 28.9784, timezone: "Europe/Istanbul")
    static let london = LocationConfig(cityName: "London", lat: 51.5074, lng: -0.1278, timezone: "Europe/London")

    static let presets: [LocationConfig] = [.cairo, .makkah, .medina, .istanbul, .london]
}

nonisolated struct CalculationConfig: Codable, Sendable {
    var method: CalculationMethod
    var madhab: Madhab
    var offsetsMinutes: PrayerOffsets

    static let `default` = CalculationConfig(method: .egyptian, madhab: .shafi, offsetsMinutes: .zero)
}

nonisolated struct PrayerOffsets: Codable, Sendable {
    var fajr: Int
    var dhuhr: Int
    var asr: Int
    var maghrib: Int
    var isha: Int

    static let zero = PrayerOffsets(fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0)

    func offset(for prayer: Prayer) -> Int {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

nonisolated struct IqamaConfig: Codable, Sendable, Equatable {
    var enabled: Bool
    var iqamaMinutes: PrayerMinutes
    var mode: String

    static let `default` = IqamaConfig(enabled: true, iqamaMinutes: .defaultMinutes, mode: "afterAdhan")
}

nonisolated struct PrayerMinutes: Codable, Sendable, Equatable {
    var fajr: Int
    var dhuhr: Int
    var asr: Int
    var maghrib: Int
    var isha: Int

    static let defaultMinutes = PrayerMinutes(fajr: 20, dhuhr: 15, asr: 15, maghrib: 10, isha: 15)

    func minutes(for prayer: Prayer) -> Int {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

nonisolated struct JumuahConfig: Codable, Sendable, Equatable {
    var enabled: Bool
    var jumuahTime: String
    var jumuahIqamaMinutes: Int
    var secondJumuahEnabled: Bool
    var secondJumuahTime: String

    static let `default` = JumuahConfig(
        enabled: true,
        jumuahTime: "12:30",
        jumuahIqamaMinutes: 15,
        secondJumuahEnabled: false,
        secondJumuahTime: "13:30"
    )
}

nonisolated struct DateDisplayConfig: Codable, Sendable {
    var showGregorian: Bool
    var showHijri: Bool
    var showWeekdayArabic: Bool
    var showWeekdayEnglish: Bool

    static let `default` = DateDisplayConfig(showGregorian: true, showHijri: true, showWeekdayArabic: true, showWeekdayEnglish: false)
}

nonisolated struct DisplayConfig: Codable, Sendable {
    var language: AppLanguage
    var brightness: Int
    var layout: LayoutPreset
    var showDhikrTicker: Bool
    var dhikrSource: String
    var tickerDirection: TickerDirection
    var pauseTickerDuringAdhan: Bool
    var lockLayout: Bool

    static let `default` = DisplayConfig(
        language: .ar,
        brightness: 80,
        layout: .wideV1,
        showDhikrTicker: true,
        dhikrSource: "built-in",
        tickerDirection: .ltr,
        pauseTickerDuringAdhan: true,
        lockLayout: false
    )
}

nonisolated struct BrightnessSchedule: Codable, Sendable, Equatable {
    var enabled: Bool
    var dayBrightness: Int
    var nightBrightness: Int
    var dayStartHour: Int
    var nightStartHour: Int

    static let `default` = BrightnessSchedule(
        enabled: false,
        dayBrightness: 80,
        nightBrightness: 30,
        dayStartHour: 6,
        nightStartHour: 20
    )
}

nonisolated struct PushTarget: Codable, Sendable {
    var baseUrl: String
    var apiKey: String
    var useHMAC: Bool
    var hmacSecret: String
    var transportMode: TransportMode
    var bleDeviceName: String

    static let `default` = PushTarget(
        baseUrl: "http://masjidclock.local:8787",
        apiKey: "211119",
        useHMAC: false,
        hmacSecret: "",
        transportMode: .wifi,
        bleDeviceName: "MasjidDisplay"
    )
}

nonisolated struct PushHistoryEntry: Codable, Sendable, Identifiable {
    let id: String
    let timestamp: Date
    let status: PushResultStatus
    let message: String
    let pushType: PushType
    let transport: String

    init(status: PushResultStatus, message: String, pushType: PushType = .lightSync, transport: String = "wifi") {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.status = status
        self.message = message
        self.pushType = pushType
        self.transport = transport
    }
}

nonisolated struct AdvancedConfig: Codable, Sendable {
    var adhanActiveSeconds: Int
    var prayerInProgressMinutes: Int
    var scheduleMode: String

    static let `default` = AdvancedConfig(adhanActiveSeconds: 120, prayerInProgressMinutes: 10, scheduleMode: "simulated")
}

nonisolated struct PrayerTime: Codable, Sendable, Identifiable {
    var id: String { prayer.rawValue }
    let prayer: Prayer
    var time: Date
    var iqamaTime: Date?
    var isJumuah: Bool

    init(prayer: Prayer, time: Date, iqamaTime: Date? = nil, isJumuah: Bool = false) {
        self.prayer = prayer
        self.time = time
        self.iqamaTime = iqamaTime
        self.isJumuah = isJumuah
    }
}

nonisolated struct ScreenPreset: Sendable, Identifiable {
    let id: String
    let name: String
    let width: Int
    let height: Int

    static let presets: [ScreenPreset] = [
        ScreenPreset(id: "1080p", name: "1920×1080", width: 1920, height: 1080),
        ScreenPreset(id: "1366", name: "1366×768", width: 1366, height: 768),
        ScreenPreset(id: "720p", name: "1280×720", width: 1280, height: 720),
        ScreenPreset(id: "xga", name: "1024×768", width: 1024, height: 768),
        ScreenPreset(id: "led", name: "800×480", width: 800, height: 480),
    ]
}
