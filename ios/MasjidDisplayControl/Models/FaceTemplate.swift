import SwiftUI

nonisolated enum FaceId: String, Codable, CaseIterable, Sendable, Hashable {
    case classicSplit = "classic-split-v1"
    case archFrame = "arch-frame-v1"
    case minimalNoor = "minimal-noor-v1"
    case ledBoard = "led-board-v1"
    case smartGlass = "smart-glass-v1"
    case ottomanGold = "ottoman-gold-v1"

    var displayName: String {
        switch self {
        case .classicSplit: return "Classic Split"
        case .archFrame: return "Arch Frame"
        case .minimalNoor: return "Minimal Noor"
        case .ledBoard: return "LED Board"
        case .smartGlass: return "Smart Glass"
        case .ottomanGold: return "Ottoman Gold"
        }
    }

    var displayNameAr: String {
        switch self {
        case .classicSplit: return "كلاسيكي مقسّم"
        case .archFrame: return "إطار القوس"
        case .minimalNoor: return "نور بسيط"
        case .ledBoard: return "لوحة LED"
        case .smartGlass: return "زجاج ذكي"
        case .ottomanGold: return "ذهب عثماني"
        }
    }

    var icon: String {
        switch self {
        case .classicSplit: return "rectangle.split.2x1.fill"
        case .archFrame: return "archivebox.fill"
        case .minimalNoor: return "sun.min.fill"
        case .ledBoard: return "tablecells.fill"
        case .smartGlass: return "rectangle.on.rectangle.angled"
        case .ottomanGold: return "seal.fill"
        }
    }

    var description: String {
        switch self {
        case .classicSplit: return "Clock & date on the left, prayer table on the right. Classic mosque display."
        case .archFrame: return "Centered arch motif with clock in a decorative frame."
        case .minimalNoor: return "Ultra-clean with a large hero clock and compact prayer row."
        case .ledBoard: return "Horizontal scoreboard rows. High density, maximum readability."
        case .smartGlass: return "Floating frosted-glass panels with depth and translucency."
        case .ottomanGold: return "Ornate symmetric design with decorative borders and rich detail."
        }
    }

    var defaultThemeId: ThemeId {
        switch self {
        case .classicSplit: return .islamicGeoDark
        case .archFrame: return .ottomanGoldNight
        case .minimalNoor: return .minimalNoor
        case .ledBoard: return .ledDigitalPremium
        case .smartGlass: return .smartGlass
        case .ottomanGold: return .ottomanClassic
        }
    }
}

nonisolated enum FaceComponentId: String, Codable, CaseIterable, Sendable, Hashable {
    case clock
    case dateBlock
    case prayerTable
    case nextPrayerCard
    case countdownRing
    case countdownText
    case phaseBadge
    case ticker
    case footer

    var displayName: String {
        switch self {
        case .clock: return "Clock"
        case .dateBlock: return "Date Block"
        case .prayerTable: return "Prayer Table"
        case .nextPrayerCard: return "Next Prayer Card"
        case .countdownRing: return "Countdown Ring"
        case .countdownText: return "Countdown Text"
        case .phaseBadge: return "Phase Badge"
        case .ticker: return "Ticker"
        case .footer: return "Footer"
        }
    }

    var displayNameAr: String {
        switch self {
        case .clock: return "الساعة"
        case .dateBlock: return "التاريخ"
        case .prayerTable: return "جدول الصلاة"
        case .nextPrayerCard: return "الصلاة القادمة"
        case .countdownRing: return "حلقة العد"
        case .countdownText: return "نص العد"
        case .phaseBadge: return "شارة المرحلة"
        case .ticker: return "الشريط المتحرك"
        case .footer: return "التذييل"
        }
    }

    var icon: String {
        switch self {
        case .clock: return "clock.fill"
        case .dateBlock: return "calendar"
        case .prayerTable: return "list.bullet.rectangle.fill"
        case .nextPrayerCard: return "forward.fill"
        case .countdownRing: return "circle.dashed"
        case .countdownText: return "timer"
        case .phaseBadge: return "bell.badge.fill"
        case .ticker: return "text.line.first.and.arrowtriangle.forward"
        case .footer: return "dock.rectangle"
        }
    }
}

nonisolated enum ScreenBreakpoint: String, Codable, Sendable {
    case large
    case medium
    case small
    case tiny

    static func from(width: CGFloat, height: CGFloat) -> ScreenBreakpoint {
        if width >= 1600 { return .large }
        if width >= 1200 { return .medium }
        if width >= 900 { return .small }
        return .tiny
    }

    var safeMargin: CGFloat {
        switch self {
        case .large: return 24
        case .medium: return 20
        case .small: return 16
        case .tiny: return 10
        }
    }

    var baseFontScale: CGFloat {
        switch self {
        case .large: return 1.0
        case .medium: return 0.82
        case .small: return 0.68
        case .tiny: return 0.50
        }
    }
}

nonisolated struct FaceTemplate: Sendable, Identifiable {
    let id: FaceId
    let defaultComponents: Set<FaceComponentId>
    let supportedComponents: Set<FaceComponentId>

    static let allFaces: [FaceTemplate] = [
        .classicSplit,
        .archFrame,
        .minimalNoor,
        .ledBoard,
        .smartGlass,
        .ottomanGold,
    ]

    static func face(for id: FaceId) -> FaceTemplate {
        allFaces.first { $0.id == id } ?? .classicSplit
    }

    static let classicSplit = FaceTemplate(
        id: .classicSplit,
        defaultComponents: [.clock, .dateBlock, .prayerTable, .countdownText, .ticker, .footer, .phaseBadge],
        supportedComponents: Set(FaceComponentId.allCases)
    )

    static let archFrame = FaceTemplate(
        id: .archFrame,
        defaultComponents: [.clock, .dateBlock, .prayerTable, .countdownText, .phaseBadge, .ticker, .footer],
        supportedComponents: Set(FaceComponentId.allCases)
    )

    static let minimalNoor = FaceTemplate(
        id: .minimalNoor,
        defaultComponents: [.clock, .dateBlock, .prayerTable, .countdownText, .footer],
        supportedComponents: Set(FaceComponentId.allCases)
    )

    static let ledBoard = FaceTemplate(
        id: .ledBoard,
        defaultComponents: [.clock, .prayerTable, .countdownText, .ticker, .phaseBadge, .footer],
        supportedComponents: Set(FaceComponentId.allCases)
    )

    static let smartGlass = FaceTemplate(
        id: .smartGlass,
        defaultComponents: [.clock, .dateBlock, .prayerTable, .nextPrayerCard, .ticker, .footer, .phaseBadge],
        supportedComponents: Set(FaceComponentId.allCases)
    )

    static let ottomanGold = FaceTemplate(
        id: .ottomanGold,
        defaultComponents: [.clock, .dateBlock, .prayerTable, .countdownText, .ticker, .footer, .phaseBadge],
        supportedComponents: Set(FaceComponentId.allCases)
    )
}
