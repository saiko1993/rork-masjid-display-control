import SwiftUI

enum DSTokens {
    enum Font {
        static let largeTitle: SwiftUI.Font = .largeTitle.weight(.bold)
        static let title: SwiftUI.Font = .title2.weight(.bold)
        static let headline: SwiftUI.Font = .headline
        static let subhead: SwiftUI.Font = .subheadline
        static let body: SwiftUI.Font = .subheadline
        static let caption: SwiftUI.Font = .caption
        static let caption2: SwiftUI.Font = .caption2
        static let mono: SwiftUI.Font = .system(.body, design: .monospaced, weight: .semibold)
        static let monoSmall: SwiftUI.Font = .system(.caption, design: .monospaced, weight: .medium)

        static let sectionTitle: SwiftUI.Font = .headline
        static let settingsLabel: SwiftUI.Font = .subheadline
        static let settingsValue: SwiftUI.Font = .subheadline.weight(.medium)
        static let chipLabel: SwiftUI.Font = .caption.weight(.semibold)
        static let chipIcon: SwiftUI.Font = .caption2.weight(.bold)
        static let tileTitle: SwiftUI.Font = .subheadline.weight(.semibold)
        static let tileSubtitle: SwiftUI.Font = .caption2
    }

    enum ButtonSize {
        static let tileHeight: CGFloat = 84
        static let tileIconSize: CGFloat = 22
        static let primaryHeight: CGFloat = 50
        static let compactHeight: CGFloat = 36
        static let minTapTarget: CGFloat = 44
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
