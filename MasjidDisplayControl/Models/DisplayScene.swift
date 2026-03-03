import Foundation

nonisolated struct DisplayScene: Codable, Sendable {
    let version: String
    let themeId: String
    let layout: String
    let screenWidth: Int
    let screenHeight: Int
    let scaleFactor: Double
    let isCompact: Bool

    let clock: ClockElement
    let dateBlock: DateBlockElement
    let countdown: CountdownElement
    let prayerTable: PrayerTableElement
    let ticker: TickerElement
    let phaseOverlay: PhaseOverlayElement
    let footer: FooterElement

    nonisolated struct ClockElement: Codable, Sendable {
        let hour: String
        let minute: String
        let second: String
    }

    nonisolated struct DateBlockElement: Codable, Sendable {
        let arabicWeekday: String?
        let englishWeekday: String?
        let hijriDate: String?
        let gregorianDate: String?
    }

    nonisolated struct CountdownElement: Codable, Sendable {
        let phase: String
        let currentPrayer: String?
        let nextPrayer: String?
        let label: String
        let labelAr: String
        let countdownSeconds: Int
        let adhanRemainingSeconds: Int
        let iqamaCountdownSeconds: Int
        let isJumuah: Bool
    }

    nonisolated struct PrayerTableElement: Codable, Sendable {
        let entries: [PrayerEntry]
        let highlightedPrayer: String?
        let activePrayer: String?
        let language: String
        let density: String
    }

    nonisolated struct PrayerEntry: Codable, Sendable {
        let prayer: String
        let adhanTime: String
        let iqamaTime: String?
        let isJumuah: Bool
        let nameAr: String
        let nameEn: String
        let icon: String
    }

    nonisolated struct TickerElement: Codable, Sendable {
        let enabled: Bool
        let isPaused: Bool
        let direction: String
        let phrases: [String]
    }

    nonisolated struct PhaseOverlayElement: Codable, Sendable {
        let phase: String
        let showAdhanGlow: Bool
        let showDemoWatermark: Bool
    }

    nonisolated struct FooterElement: Codable, Sendable {
        let cityName: String
        let isSimulated: Bool
    }
}
