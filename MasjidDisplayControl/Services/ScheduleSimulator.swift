import Foundation

struct ScheduleSimulator {
    static func generateSchedule(
        for location: LocationConfig,
        date: Date = Date(),
        iqamaConfig: IqamaConfig,
        jumuahConfig: JumuahConfig = .default
    ) -> [PrayerTime] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isFriday = weekday == 6

        let baseHours: [(Prayer, Int, Int)] = switch location.cityName {
        case "Makkah":
            [(.fajr, 5, 15), (.dhuhr, 12, 20), (.asr, 15, 35), (.maghrib, 18, 25), (.isha, 19, 55)]
        case "Medina":
            [(.fajr, 5, 10), (.dhuhr, 12, 15), (.asr, 15, 30), (.maghrib, 18, 20), (.isha, 19, 50)]
        case "Istanbul":
            [(.fajr, 5, 45), (.dhuhr, 13, 10), (.asr, 16, 20), (.maghrib, 19, 0), (.isha, 20, 35)]
        case "London":
            [(.fajr, 5, 30), (.dhuhr, 12, 55), (.asr, 15, 45), (.maghrib, 18, 30), (.isha, 20, 10)]
        default:
            [(.fajr, 4, 50), (.dhuhr, 12, 5), (.asr, 15, 25), (.maghrib, 18, 10), (.isha, 19, 40)]
        }

        return baseHours.map { prayer, hour, minute in
            var components = calendar.dateComponents([.year, .month, .day], from: date)

            let isJumuahDhuhr = isFriday && jumuahConfig.enabled && prayer == .dhuhr

            if isJumuahDhuhr {
                let parts = jumuahConfig.jumuahTime.split(separator: ":")
                components.hour = parts.count >= 1 ? Int(parts[0]) ?? hour : hour
                components.minute = parts.count >= 2 ? Int(parts[1]) ?? minute : minute
            } else {
                components.hour = hour
                components.minute = minute
            }
            components.second = 0
            let time = calendar.date(from: components) ?? date

            var iqamaTime: Date?
            if iqamaConfig.enabled {
                let mins = isJumuahDhuhr ? jumuahConfig.jumuahIqamaMinutes : iqamaConfig.iqamaMinutes.minutes(for: prayer)
                iqamaTime = time.addingTimeInterval(Double(mins) * 60)
            }

            return PrayerTime(prayer: prayer, time: time, iqamaTime: iqamaTime, isJumuah: isJumuahDhuhr)
        }
    }
}
