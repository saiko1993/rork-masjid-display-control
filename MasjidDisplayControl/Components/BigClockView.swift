import SwiftUI

struct BigClockView: View {
    let time: Date
    let theme: ThemeDefinition
    let scaleFactor: CGFloat

    var body: some View {
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        let h = String(format: "%02d", comps.hour ?? 0)
        let m = String(format: "%02d", comps.minute ?? 0)
        let s = String(format: "%02d", comps.second ?? 0)

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
        }
        .foregroundStyle(theme.palette.textPrimary)
        .monospacedDigit()
    }
}
