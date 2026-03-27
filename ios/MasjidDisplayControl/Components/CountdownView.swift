import SwiftUI

struct CountdownView: View {
    let stateInfo: PrayerStateInfo
    let theme: ThemeDefinition
    let language: AppLanguage
    let scaleFactor: CGFloat

    var body: some View {
        VStack(spacing: 6 * scaleFactor) {
            switch stateInfo.phase {
            case .normal:
                if let next = stateInfo.nextPrayer {
                    Text(language == .ar ? "التالي: \(next.displayNameAr)" : "Next: \(next.displayName)")
                        .font(.system(size: 14 * scaleFactor, weight: .medium, design: language == .ar ? theme.typography.arabicFontDesign : theme.typography.latinFontDesign))
                        .foregroundStyle(theme.palette.textSecondary)

                    countdownDigits(formatCountdown(stateInfo.countdownSeconds), color: theme.palette.primary, size: 32, glowColor: theme.palette.primary, glowIntensity: 0.3)
                }

            case .adhanActive:
                if let prayer = stateInfo.currentPrayer {
                    let label = stateInfo.isJumuah
                        ? (language == .ar ? "حان الآن وقت صلاة الجمعة" : "Time for Jumu'ah Prayer")
                        : (language == .ar ? "حان الآن وقت صلاة \(prayer.displayNameAr)" : "Time for \(prayer.displayName) Prayer")
                    Text(label)
                        .font(.system(size: 16 * scaleFactor, weight: .bold, design: language == .ar ? theme.typography.arabicFontDesign : theme.typography.latinFontDesign))
                        .foregroundStyle(theme.palette.accent)
                        .multilineTextAlignment(.center)

                    countdownDigits(formatCountdown(stateInfo.adhanRemainingSeconds), color: theme.palette.accent, size: 24, glowColor: theme.palette.accent, glowIntensity: 0.5)
                }

            case .iqamaCountdown:
                Text(language == .ar ? "الإقامة بعد" : "Iqama in")
                    .font(.system(size: 14 * scaleFactor, weight: .medium))
                    .foregroundStyle(theme.palette.textSecondary)

                countdownDigits(formatCountdown(stateInfo.iqamaCountdownSeconds), color: theme.palette.accent, size: 32, glowColor: theme.palette.accent, glowIntensity: 0.4)

            case .prayerInProgress:
                if let prayer = stateInfo.currentPrayer {
                    let label = stateInfo.isJumuah
                        ? (language == .ar ? "صلاة الجمعة جارية" : "Jumu'ah in Progress")
                        : (language == .ar ? "صلاة \(prayer.displayNameAr) جارية" : "\(prayer.displayName) in Progress")
                    Text(label)
                        .font(.system(size: 16 * scaleFactor, weight: .semibold))
                        .foregroundStyle(theme.palette.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func countdownDigits(_ text: String, color: Color, size: CGFloat, glowColor: Color, glowIntensity: CGFloat) -> some View {
        let glowRadius = theme.layers.countdownGlowRadius * scaleFactor

        switch theme.layers.cardElevation {
        case .inset:
            Text(text)
                .font(.system(size: size * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                .foregroundStyle(color)
                .monospacedDigit()
                .shadow(color: .black.opacity(0.3), radius: 1 * scaleFactor, x: 1 * scaleFactor, y: 1 * scaleFactor)
                .shadow(color: color.opacity(glowIntensity * 0.5), radius: glowRadius * 0.4)

        case .neumorphic:
            Text(text)
                .font(.system(size: size * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                .foregroundStyle(color)
                .monospacedDigit()
                .shadow(color: color.opacity(glowIntensity * 0.6), radius: glowRadius * 0.5)

        default:
            Text(text)
                .font(.system(size: size * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                .foregroundStyle(color)
                .monospacedDigit()
                .shadow(color: glowColor.opacity(glowIntensity), radius: glowRadius * 0.5)
        }
    }

    private func formatCountdown(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
