import SwiftUI

struct DhikrTickerView: View {
    let theme: ThemeDefinition
    let scaleFactor: CGFloat
    let direction: TickerDirection
    let isPaused: Bool

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    init(theme: ThemeDefinition, scaleFactor: CGFloat, direction: TickerDirection = .ltr, isPaused: Bool = false) {
        self.theme = theme
        self.scaleFactor = scaleFactor
        self.direction = direction
        self.isPaused = isPaused
    }

    private var tickerText: String {
        DhikrData.phrases.joined(separator: "    ◆    ")
    }

    private var singleSegment: String {
        tickerText + "    ◆    "
    }

    private var fontSize: CGFloat {
        13 * scaleFactor
    }

    var body: some View {
        GeometryReader { geo in
            let _ = updateContainerWidth(geo.size.width)
            HStack(spacing: 0) {
                tickerSegment
                tickerSegment
                tickerSegment
            }
            .offset(x: offset)
        }
        .frame(height: 24 * scaleFactor)
        .clipped()
        .padding(.horizontal, 8 * scaleFactor)
        .background(theme.layers.tickerBackground ?? theme.palette.surface.opacity(0.3))
        .opacity(isPaused ? 0.3 : 1.0)
        .onAppear {
            startScrolling()
        }
        .onChange(of: isPaused) { _, newValue in
            if !newValue {
                startScrolling()
            }
        }
        .onChange(of: textWidth) { _, _ in
            startScrolling()
        }
    }

    private var tickerSegment: some View {
        Text(singleSegment)
            .font(.system(size: fontSize, weight: .medium, design: theme.typography.arabicFontDesign))
            .foregroundStyle(theme.palette.accent)
            .fixedSize()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            if textWidth == 0 {
                                textWidth = geo.size.width
                            }
                        }
                }
            )
    }

    private func updateContainerWidth(_ width: CGFloat) {
        if containerWidth != width {
            Task { @MainActor in
                containerWidth = width
            }
        }
    }

    private func startScrolling() {
        guard textWidth > 0, !isPaused else { return }

        offset = direction == .rtl ? -textWidth : 0

        let speed: CGFloat = 30.0
        let duration = textWidth / speed

        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = direction == .rtl ? 0 : -textWidth
        }
    }
}
