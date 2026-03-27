import SwiftUI

struct DateBlockView: View {
    let date: Date
    let config: DateDisplayConfig
    let theme: ThemeDefinition
    let scaleFactor: CGFloat

    var body: some View {
        VStack(spacing: 4 * scaleFactor) {
            if config.showWeekdayArabic {
                Text(HijriDateHelper.arabicWeekday(from: date))
                    .font(.system(size: 18 * scaleFactor, weight: theme.typography.headingWeight, design: theme.typography.arabicFontDesign))
                    .foregroundStyle(theme.palette.accent)
            }

            if config.showWeekdayEnglish {
                Text(HijriDateHelper.englishWeekday(from: date))
                    .font(.system(size: 14 * scaleFactor, weight: .medium, design: theme.typography.latinFontDesign))
                    .foregroundStyle(theme.palette.textSecondary)
            }

            if config.showHijri {
                Text(HijriDateHelper.hijriString(from: date))
                    .font(.system(size: 14 * scaleFactor, weight: .medium, design: theme.typography.arabicFontDesign))
                    .foregroundStyle(theme.palette.textPrimary)
            }

            if config.showGregorian {
                Text(HijriDateHelper.gregorianString(from: date))
                    .font(.system(size: 12 * scaleFactor, weight: .regular, design: theme.typography.latinFontDesign))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}
