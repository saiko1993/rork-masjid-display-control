import SwiftUI

enum ElevationLevel: Int, CaseIterable {
    case level0 = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    case level5 = 5

    var shadowRadius: CGFloat {
        switch self {
        case .level0: return 0
        case .level1: return 2
        case .level2: return 6
        case .level3: return 12
        case .level4: return 20
        case .level5: return 30
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .level0: return 0
        case .level1: return 1
        case .level2: return 3
        case .level3: return 6
        case .level4: return 10
        case .level5: return 14
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .level0: return 0
        case .level1: return 0.08
        case .level2: return 0.14
        case .level3: return 0.22
        case .level4: return 0.3
        case .level5: return 0.4
        }
    }

    var highlightStrength: Double {
        switch self {
        case .level0: return 0
        case .level1: return 0.02
        case .level2: return 0.04
        case .level3: return 0.06
        case .level4: return 0.08
        case .level5: return 0.1
        }
    }
}

struct ElevationModifier: ViewModifier {
    let level: ElevationLevel
    var color: Color = .black

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(level.shadowOpacity),
                radius: level.shadowRadius,
                y: level.shadowY
            )
    }
}

extension View {
    func elevation(_ level: ElevationLevel, color: Color = .black) -> some View {
        modifier(ElevationModifier(level: level, color: color))
    }
}
