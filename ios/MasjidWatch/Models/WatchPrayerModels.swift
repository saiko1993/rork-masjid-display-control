import Foundation

nonisolated enum WatchPrayer: String, Codable, CaseIterable, Sendable, Identifiable {
    case fajr, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

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

    var shortName: String {
        switch self {
        case .fajr: return "FJR"
        case .dhuhr: return "DHR"
        case .asr: return "ASR"
        case .maghrib: return "MGH"
        case .isha: return "ISH"
        }
    }
}

nonisolated enum WatchPrayerPhase: String, Codable, Sendable {
    case normal
    case adhanActive = "adhan_active"
    case iqamaCountdown = "iqama_countdown"
    case prayerInProgress = "prayer_in_progress"

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .adhanActive: return "Adhan"
        case .iqamaCountdown: return "Iqama"
        case .prayerInProgress: return "Prayer"
        }
    }

    var labelAr: String {
        switch self {
        case .normal: return "عادي"
        case .adhanActive: return "أذان"
        case .iqamaCountdown: return "إقامة"
        case .prayerInProgress: return "صلاة"
        }
    }

    var accentColorName: String {
        switch self {
        case .normal: return "green"
        case .adhanActive: return "orange"
        case .iqamaCountdown: return "yellow"
        case .prayerInProgress: return "blue"
        }
    }
}

nonisolated struct WatchPrayerEntry: Codable, Sendable, Identifiable {
    var id: String { prayerKey }
    let prayerKey: String
    let nameEn: String
    let nameAr: String
    let time: Date
    let icon: String

    init(prayer: WatchPrayer, time: Date) {
        self.prayerKey = prayer.rawValue
        self.nameEn = prayer.displayName
        self.nameAr = prayer.displayNameAr
        self.time = time
        self.icon = prayer.iconName
    }
}

nonisolated struct WatchState: Codable, Sendable {
    let nextPrayerKey: String
    let nextPrayerAr: String
    let nextPrayerEn: String
    let countdownSeconds: Int
    let phase: String
    let city: String
    let prayers: [WatchPrayerEntry]
    let updatedAt: Date

    static let empty = WatchState(
        nextPrayerKey: "fajr",
        nextPrayerAr: "الفجر",
        nextPrayerEn: "Fajr",
        countdownSeconds: 0,
        phase: "normal",
        city: "",
        prayers: [],
        updatedAt: Date()
    )

    var nextPrayer: WatchPrayer? {
        WatchPrayer(rawValue: nextPrayerKey)
    }

    var prayerPhase: WatchPrayerPhase {
        WatchPrayerPhase(rawValue: phase) ?? .normal
    }

    var countdownDate: Date {
        updatedAt.addingTimeInterval(Double(countdownSeconds))
    }
}
