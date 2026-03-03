import SwiftUI

struct BigClockView: View {
    let time: Date
    let theme: ThemeDefinition
    let scaleFactor: CGFloat
    var timeFormat: TimeFormat = .twentyFour

    var body: some View {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        let rawHour = comps.hour ?? 0
        let hour: Int = timeFormat == .twelve ? (rawHour == 0 ? 12 : (rawHour > 12 ? rawHour - 12 : rawHour)) : rawHour
        let h = timeFormat == .twelve ? String(format: "%d", hour) : String(format: "%02d", hour)
        let m = String(format: "%02d", comps.minute ?? 0)
        let s = String(format: "%02d", comps.second ?? 0)
        let period = rawHour >= 12 ? "PM" : "AM"

        HStack(spacing: 2 * scaleFactor) {
            Text(h)
                .font(.system(size: 64 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
            Text(":")
                .font(.system(size: 56 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                .opacity(0.7)
            Text(m)
                .font(.system(size: 64 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
            Text(":")
                .font(.system(size: 56 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                .opacity(0.7)
            Text(s)
                .font(.system(size: 64 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))

            if timeFormat == .twelve {
                Text(period)
                    .font(.system(size: 18 * scaleFactor, weight: .semibold, design: theme.typography.timeFontDesign))
                    .foregroundStyle(theme.palette.textSecondary)
                    .padding(.leading, 4 * scaleFactor)
                    .offset(y: -16 * scaleFactor)
            }
        }
        .foregroundStyle(theme.palette.textPrimary)
        .monospacedDigit()
    }
}
