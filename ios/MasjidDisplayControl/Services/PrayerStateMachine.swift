import Foundation

struct PrayerStateInfo: Sendable {
    let phase: PrayerPhase
    let currentPrayer: Prayer?
    let nextPrayer: Prayer?
    let nextPrayerTime: Date?
    let countdownSeconds: Int
    let adhanRemainingSeconds: Int
    let iqamaCountdownSeconds: Int
    let phaseLabel: String
    let phaseLabelAr: String
    let isJumuah: Bool
}

struct PrayerStateMachine {
    static func evaluate(
        now: Date,
        schedule: [PrayerTime],
        adhanActiveSeconds: Int,
        iqamaConfig: IqamaConfig,
        prayerInProgressMinutes: Int
    ) -> PrayerStateInfo {
        guard !schedule.isEmpty else {
            return PrayerStateInfo(
                phase: .normal,
                currentPrayer: nil,
                nextPrayer: nil,
                nextPrayerTime: nil,
                countdownSeconds: 0,
                adhanRemainingSeconds: 0,
                iqamaCountdownSeconds: 0,
                phaseLabel: "No schedule",
                phaseLabelAr: "لا يوجد جدول",
                isJumuah: false
            )
        }

        for prayerTime in schedule.reversed() {
            guard now >= prayerTime.time else { continue }

            let iqamaMins = iqamaConfig.enabled ? iqamaConfig.iqamaMinutes.minutes(for: prayerTime.prayer) : 0

            let safeIqamaMins: Int
            if prayerTime.prayer == .maghrib && iqamaMins > 8 {
                safeIqamaMins = min(iqamaMins, 8)
            } else {
                safeIqamaMins = iqamaMins
            }

            let adhanEnd = prayerTime.time.addingTimeInterval(Double(adhanActiveSeconds))
            let iqamaEnd = adhanEnd.addingTimeInterval(Double(safeIqamaMins) * 60)
            let prayerEnd = iqamaEnd.addingTimeInterval(Double(prayerInProgressMinutes) * 60)

            let jumuahLabel = prayerTime.isJumuah
            let actualNext = nextPrayerAfter(prayerTime.prayer, in: schedule)
            let actualNextTime = nextTimeAfter(prayerTime.prayer, in: schedule)

            if now < adhanEnd {
                let adhanRemaining = Int(adhanEnd.timeIntervalSince(now))
                let prayerLabel = jumuahLabel ? "Jumu'ah" : prayerTime.prayer.displayName
                let prayerLabelAr = jumuahLabel ? "الجمعة" : prayerTime.prayer.displayNameAr
                return PrayerStateInfo(
                    phase: .adhanActive,
                    currentPrayer: prayerTime.prayer,
                    nextPrayer: actualNext,
                    nextPrayerTime: actualNextTime,
                    countdownSeconds: 0,
                    adhanRemainingSeconds: adhanRemaining,
                    iqamaCountdownSeconds: adhanRemaining + (safeIqamaMins * 60),
                    phaseLabel: "Adhan: \(prayerLabel)",
                    phaseLabelAr: "حان الآن وقت صلاة \(prayerLabelAr)",
                    isJumuah: jumuahLabel
                )
            }

            if iqamaConfig.enabled && now < iqamaEnd {
                let remaining = Int(iqamaEnd.timeIntervalSince(now))
                return PrayerStateInfo(
                    phase: .iqamaCountdown,
                    currentPrayer: prayerTime.prayer,
                    nextPrayer: actualNext,
                    nextPrayerTime: actualNextTime,
                    countdownSeconds: 0,
                    adhanRemainingSeconds: 0,
                    iqamaCountdownSeconds: remaining,
                    phaseLabel: "Iqama in \(remaining / 60):\(String(format: "%02d", remaining % 60))",
                    phaseLabelAr: "الإقامة بعد \(remaining / 60):\(String(format: "%02d", remaining % 60))",
                    isJumuah: jumuahLabel
                )
            }

            let effectiveEnd = iqamaConfig.enabled ? iqamaEnd : adhanEnd
            if now >= effectiveEnd && now < prayerEnd {
                let remaining = Int(prayerEnd.timeIntervalSince(now))
                let prayerLabel = jumuahLabel ? "Jumu'ah" : prayerTime.prayer.displayName
                let prayerLabelAr = jumuahLabel ? "الجمعة" : prayerTime.prayer.displayNameAr
                return PrayerStateInfo(
                    phase: .prayerInProgress,
                    currentPrayer: prayerTime.prayer,
                    nextPrayer: actualNext,
                    nextPrayerTime: actualNextTime,
                    countdownSeconds: remaining,
                    adhanRemainingSeconds: 0,
                    iqamaCountdownSeconds: 0,
                    phaseLabel: "\(prayerLabel) in progress",
                    phaseLabelAr: "صلاة \(prayerLabelAr) جارية",
                    isJumuah: jumuahLabel
                )
            }

            break
        }

        let upcomingPrayer = schedule.first { $0.time > now }

        if let upcoming = upcomingPrayer {
            let countdown = Int(upcoming.time.timeIntervalSince(now))
            return PrayerStateInfo(
                phase: .normal,
                currentPrayer: nil,
                nextPrayer: upcoming.prayer,
                nextPrayerTime: upcoming.time,
                countdownSeconds: max(0, countdown),
                adhanRemainingSeconds: 0,
                iqamaCountdownSeconds: 0,
                phaseLabel: "Next: \(upcoming.prayer.displayName)",
                phaseLabelAr: "التالي: \(upcoming.prayer.displayNameAr)",
                isJumuah: false
            )
        }

        let fajrTomorrow = estimateFajrTomorrow(from: schedule)
        let fajrCountdown = fajrTomorrow.map { Int($0.timeIntervalSince(now)) } ?? 0

        return PrayerStateInfo(
            phase: .normal,
            currentPrayer: nil,
            nextPrayer: fajrTomorrow != nil ? .fajr : nil,
            nextPrayerTime: fajrTomorrow,
            countdownSeconds: max(0, fajrCountdown),
            adhanRemainingSeconds: 0,
            iqamaCountdownSeconds: 0,
            phaseLabel: fajrTomorrow != nil ? "Next: Fajr (tomorrow)" : "All prayers completed",
            phaseLabelAr: fajrTomorrow != nil ? "التالي: الفجر (غداً)" : "انتهت صلوات اليوم",
            isJumuah: false
        )
    }

    private static func nextPrayerAfter(_ prayer: Prayer, in schedule: [PrayerTime]) -> Prayer? {
        guard let idx = schedule.firstIndex(where: { $0.prayer == prayer }) else { return nil }
        let nextIdx = idx + 1
        return nextIdx < schedule.count ? schedule[nextIdx].prayer : nil
    }

    private static func nextTimeAfter(_ prayer: Prayer, in schedule: [PrayerTime]) -> Date? {
        guard let idx = schedule.firstIndex(where: { $0.prayer == prayer }) else { return nil }
        let nextIdx = idx + 1
        return nextIdx < schedule.count ? schedule[nextIdx].time : nil
    }

    private static func estimateFajrTomorrow(from schedule: [PrayerTime]) -> Date? {
        guard let fajr = schedule.first(where: { $0.prayer == .fajr }) else { return nil }
        return Calendar.current.date(byAdding: .day, value: 1, to: fajr.time)
    }
}
