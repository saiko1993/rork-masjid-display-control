import SwiftUI

struct DhikrTickerView: View {
    let theme: ThemeDefinition
    let scaleFactor: CGFloat
    let direction: TickerDirection
    let isPaused: Bool

    @State private var startDate: Date = Date()
    @State private var pausedElapsed: TimeInterval = 0

    init(theme: ThemeDefinition, scaleFactor: CGFloat, direction: TickerDirection = .ltr, isPaused: Bool = false) {
        self.theme = theme
        self.scaleFactor = scaleFactor
        self.direction = direction
        self.isPaused = isPaused
    }

    private var tickerText: String {
        DhikrData.phrases.joined(separator: "    ◆    ")
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
            Canvas { context, size in
                let singleText = tickerText + "    ◆    "
                let doubledText = singleText + singleText + singleText
                let resolved = context.resolve(
                    Text(doubledText)
                        .font(.system(size: 13 * scaleFactor, weight: .medium, design: theme.typography.arabicFontDesign))
                        .foregroundStyle(theme.palette.accent)
                )
                let textSize = resolved.measure(in: CGSize(width: .infinity, height: size.height))
                let singleWidth = textSize.width / 3.0

                guard singleWidth > 0 else { return }

                let elapsed: TimeInterval
                if isPaused {
                    elapsed = pausedElapsed
                } else {
                    elapsed = pausedElapsed + timeline.date.timeIntervalSince(startDate)
                }

                let speed: Double = 30.0
                let progress = elapsed * speed
                let cycleOffset = progress.truncatingRemainder(dividingBy: singleWidth)

                let offset: CGFloat
                if direction == .rtl {
                    offset = -singleWidth + cycleOffset
                } else {
                    offset = -cycleOffset
                }

                context.draw(resolved, at: CGPoint(x: offset + textSize.width / 2, y: size.height / 2))
            }
        }
        .frame(height: 24 * scaleFactor)
        .clipped()
        .padding(.horizontal, 8 * scaleFactor)
        .background(theme.layers.tickerBackground ?? theme.palette.surface.opacity(0.3))
        .opacity(isPaused ? 0.3 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isPaused)
        .onChange(of: isPaused) { oldValue, newValue in
            if newValue {
                pausedElapsed += Date().timeIntervalSince(startDate)
            } else {
                startDate = Date()
            }
        }
    }
}
