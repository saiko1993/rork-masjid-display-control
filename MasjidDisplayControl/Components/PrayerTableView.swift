import SwiftUI

struct PrayerTableView: View {
    let schedule: [PrayerTime]
    let stateInfo: PrayerStateInfo
    let theme: ThemeDefinition
    let language: AppLanguage
    let scaleFactor: CGFloat
    let isCompact: Bool

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    var body: some View {
        let density = theme.tokens.tableDensity
        let verticalPad: CGFloat = density == .compact ? 4 : 6

        VStack(spacing: verticalPad * scaleFactor) {
            headerRow

            ForEach(schedule) { prayerTime in
                let isNext = stateInfo.nextPrayer == prayerTime.prayer && stateInfo.phase == .normal
                let isActive = stateInfo.currentPrayer == prayerTime.prayer && stateInfo.phase != .normal

                if theme.layers.tableRowSeparator && prayerTime.prayer != schedule.first?.prayer {
                    Rectangle()
                        .fill(theme.palette.textSecondary.opacity(0.1))
                        .frame(height: 0.5 * scaleFactor)
                        .padding(.horizontal, theme.layers.tableRowInset ? 12 * scaleFactor : 0)
                }

                prayerRow(prayerTime: prayerTime, isNext: isNext, isActive: isActive, verticalPad: verticalPad)
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text(language == .ar ? "الصلاة" : "Prayer")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(language == .ar ? "الأذان" : "Adhan")
                .frame(width: 70 * scaleFactor, alignment: .center)
            if !isCompact {
                Text(language == .ar ? "الإقامة" : "Iqama")
                    .frame(width: 70 * scaleFactor, alignment: .center)
            }
        }
        .font(.system(size: max(theme.tokens.minReadableFontSize, 11) * scaleFactor, weight: .semibold, design: theme.typography.latinFontDesign))
        .foregroundStyle(theme.palette.textSecondary)
        .padding(.bottom, 4 * scaleFactor)
    }

    private func prayerRow(prayerTime: PrayerTime, isNext: Bool, isActive: Bool, verticalPad: CGFloat) -> some View {
        let prayerName: String = {
            if prayerTime.isJumuah {
                return language == .ar ? "الجمعة" : "Jumu'ah"
            }
            return language == .ar ? prayerTime.prayer.displayNameAr : prayerTime.prayer.displayName
        }()

        let iconName = prayerTime.isJumuah ? "building.columns.fill" : prayerTime.prayer.iconName
        let fontSize = max(theme.tokens.minReadableFontSize, 14)

        return HStack {
            HStack(spacing: 6 * scaleFactor) {
                Image(systemName: iconName)
                    .font(.system(size: fontSize * scaleFactor))
                    .foregroundStyle(isActive ? theme.palette.accent : theme.palette.primary)
                    .frame(width: 18 * scaleFactor)

                Text(prayerName)
                    .font(.system(size: fontSize * scaleFactor, weight: isNext || isActive ? .bold : .medium, design: language == .ar ? theme.typography.arabicFontDesign : theme.typography.latinFontDesign))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(timeFormatter.string(from: prayerTime.time))
                .font(.system(size: fontSize * scaleFactor, weight: .semibold, design: theme.typography.timeFontDesign))
                .monospacedDigit()
                .frame(width: 70 * scaleFactor, alignment: .center)

            if !isCompact, let iqama = prayerTime.iqamaTime {
                Text(timeFormatter.string(from: iqama))
                    .font(.system(size: fontSize * scaleFactor, weight: .medium, design: theme.typography.timeFontDesign))
                    .monospacedDigit()
                    .frame(width: 70 * scaleFactor, alignment: .center)
            }
        }
        .foregroundStyle(isActive ? theme.palette.accent : (isNext ? theme.palette.primary : theme.palette.textPrimary))
        .padding(.vertical, verticalPad * scaleFactor)
        .padding(.horizontal, 8 * scaleFactor)
        .background(
            Group {
                if isNext {
                    theme.palette.primary.opacity(0.12)
                } else if isActive {
                    theme.palette.accent.opacity(0.15)
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(.rect(cornerRadius: 8 * scaleFactor))
    }
}
