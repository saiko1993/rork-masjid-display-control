import SwiftUI

enum DSTokens {
    enum Font {
        static let largeTitle: SwiftUI.Font = .largeTitle.weight(.bold)
        static let title: SwiftUI.Font = .title2.weight(.bold)
        static let headline: SwiftUI.Font = .headline
        static let subhead: SwiftUI.Font = .subheadline
        static let caption: SwiftUI.Font = .caption
        static let mono: SwiftUI.Font = .system(.body, design: .monospaced, weight: .semibold)
        static let monoSmall: SwiftUI.Font = .system(.caption, design: .monospaced, weight: .medium)
    }

    enum Palette {
        static let backgroundDark = SwiftUI.Color(red: 0.04, green: 0.05, blue: 0.10)
        static let backgroundMid = SwiftUI.Color(red: 0.06, green: 0.07, blue: 0.13)
        static let surfaceGlass = SwiftUI.Color.white.opacity(0.06)
        static let borderSubtle = SwiftUI.Color.white.opacity(0.12)
        static let borderBright = SwiftUI.Color.white.opacity(0.22)
        static let textMuted = SwiftUI.Color.white.opacity(0.55)
    }

    enum Duration {
        static let fast: Double = 0.15
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }
}
