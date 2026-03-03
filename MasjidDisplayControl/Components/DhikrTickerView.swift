import SwiftUI

struct DhikrTickerView: View {
    let theme: ThemeDefinition
    let scaleFactor: CGFloat
    let direction: TickerDirection
    let isPaused: Bool

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
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused)) { timeline in
            GeometryReader { geo in
                let containerWidth = geo.size.width
                Canvas { context, size in
                    let fullText = tickerText + "    ◆    " + tickerText
                    let resolved = context.resolve(
                        Text(fullText)
                            .font(.system(size: 13 * scaleFactor, weight: .medium, design: theme.typography.arabicFontDesign))
                            .foregroundStyle(theme.palette.accent)
                    )
                    let textSize = resolved.measure(in: CGSize(width: .infinity, height: size.height))
                    let singleWidth = textSize.width / 2.0

                    guard singleWidth > 0 else { return }

                    let elapsed = isPaused ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    let speed: Double = 40.0
                    let totalTravel = singleWidth
                    let progress = elapsed.truncatingRemainder(dividingBy: totalTravel / speed) / (totalTravel / speed)

                    let offset: CGFloat
                    if direction == .rtl {
                        offset = containerWidth - progress * singleWidth
                    } else {
                        offset = -progress * singleWidth
                    }

                    context.draw(resolved, at: CGPoint(x: offset + textSize.width / 2, y: size.height / 2))
                }
            }
        }
        .frame(height: 24 * scaleFactor)
        .clipped()
        .padding(.horizontal, 8 * scaleFactor)
        .background(theme.layers.tickerBackground ?? theme.palette.surface.opacity(0.3))
        .opacity(isPaused ? 0.3 : 1.0)
        .animation(.easeInOut(duration: 0.5), value: isPaused)
    }
}
