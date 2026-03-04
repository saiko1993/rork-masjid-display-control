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
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
            GeometryReader { geo in
                let containerWidth = geo.size.width
                Canvas { context, size in
                    let singleText = tickerText + "    ◆    "
                    let doubledText = singleText + singleText
                    let resolved = context.resolve(
                        Text(doubledText)
                            .font(.system(size: 13 * scaleFactor, weight: .medium, design: theme.typography.arabicFontDesign))
                            .foregroundStyle(theme.palette.accent)
                    )
                    let textSize = resolved.measure(in: CGSize(width: .infinity, height: size.height))
                    let singleWidth = textSize.width / 2.0

                    guard singleWidth > 0 else { return }

                    let elapsed = isPaused ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    let speed: Double = 30.0
                    let cycleDuration = singleWidth / speed
                    let normalizedTime = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration

                    let offset: CGFloat
                    if direction == .rtl {
                        let startX = -singleWidth
                        offset = startX + normalizedTime * singleWidth
                    } else {
                        offset = -normalizedTime * singleWidth
                    }

                    let drawPoint = CGPoint(x: offset + textSize.width / 2, y: size.height / 2)
                    context.draw(resolved, at: drawPoint)
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
