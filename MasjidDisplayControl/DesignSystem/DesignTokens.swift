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

    enum CardSize {
        static let largeHeight: CGFloat = 120
        static let largeRadius: CGFloat = 24
        static let largePadding: CGFloat = 16

        static let mediumHeight: CGFloat = 88
        static let mediumRadius: CGFloat = 20
        static let mediumPadding: CGFloat = 14

        static let smallHeight: CGFloat = 56
        static let smallRadius: CGFloat = 18
        static let smallPadding: CGFloat = 12
    }

    enum Grid {
        static let sectionSpacing: CGFloat = 20
        static let cardSpacing: CGFloat = 12
        static let chipSpacing: CGFloat = 8
        static let bottomBarHeight: CGFloat = 72
        static let bottomBarRadius: CGFloat = 28
        static let bottomBarPadding: CGFloat = 12
    }

    enum Palette {
        static let backgroundDark = SwiftUI.Color(red: 0.04, green: 0.04, blue: 0.08)
        static let backgroundMid = SwiftUI.Color(red: 0.06, green: 0.06, blue: 0.11)
        static let surfaceGlass = SwiftUI.Color.white.opacity(0.05)
        static let borderSubtle = SwiftUI.Color.white.opacity(0.10)
        static let borderBright = SwiftUI.Color.white.opacity(0.18)
        static let textMuted = SwiftUI.Color.white.opacity(0.50)

        static let accent = SwiftUI.Color(red: 0.85, green: 0.68, blue: 0.32)
        static let accentDeep = SwiftUI.Color(red: 0.18, green: 0.25, blue: 0.50)
        static let warmAmber = SwiftUI.Color(red: 0.90, green: 0.72, blue: 0.35)
        static let deepBlue = SwiftUI.Color(red: 0.22, green: 0.32, blue: 0.58)
        static let softSlate = SwiftUI.Color(red: 0.35, green: 0.38, blue: 0.45)
        static let charcoal = SwiftUI.Color(red: 0.12, green: 0.13, blue: 0.18)
    }

    enum Duration {
        static let fast: Double = 0.15
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }
}
