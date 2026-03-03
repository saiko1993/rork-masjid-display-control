import SwiftUI

nonisolated enum TimeFormat: String, Codable, CaseIterable, Sendable {
    case twelve = "12h"
    case twentyFour = "24h"

    var displayName: String {
        switch self {
        case .twelve: return "12H"
        case .twentyFour: return "24H"
        }
    }
}

nonisolated enum TickerMode: String, Codable, CaseIterable, Sendable {
    case quran = "quran"
    case custom = "custom"
    case announcements = "announcements"

    var displayName: String {
        switch self {
        case .quran: return "Quran / Dhikr"
        case .custom: return "Custom Message"
        case .announcements: return "Announcements"
        }
    }

    var icon: String {
        switch self {
        case .quran: return "book.fill"
        case .custom: return "text.bubble.fill"
        case .announcements: return "megaphone.fill"
        }
    }
}

nonisolated struct AnnouncementMessage: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var text: String
    var expiresAt: Date?
    var isPinned: Bool

    init(text: String, expiresAt: Date? = nil, isPinned: Bool = false) {
        self.id = UUID().uuidString
        self.text = text
        self.expiresAt = expiresAt
        self.isPinned = isPinned
    }
}

nonisolated struct TickerConfig: Codable, Sendable, Equatable {
    var mode: TickerMode
    var customMessage: String
    var messageExpiresAt: Date?
    var pauseDuringAdhan: Bool
    var announcements: [AnnouncementMessage]
    var rotationIntervalMinutes: Int
    var messagePriority: TickerPriority?
    var startTime: String?
    var endTime: String?

    static let `default` = TickerConfig(
        mode: .quran,
        customMessage: "",
        messageExpiresAt: nil,
        pauseDuringAdhan: true,
        announcements: [],
        rotationIntervalMinutes: 5,
        messagePriority: nil,
        startTime: nil,
        endTime: nil
    )

    var effectivePriority: TickerPriority { messagePriority ?? .normal }
}

nonisolated enum TickerPriority: String, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high
    case urgent

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

nonisolated struct ThemeColorOverride: Codable, Sendable, Equatable {
    var backgroundHex: String?
    var surfaceHex: String?
    var primaryHex: String?
    var secondaryHex: String?
    var textPrimaryHex: String?
    var textSecondaryHex: String?
    var accentHex: String?
    var adhanGlowHex: String?

    var gradientStop0Hex: String?
    var gradientStop1Hex: String?
    var gradientStop2Hex: String?
    var gradientStop3Hex: String?

    var patternOpacity: Double?
    var vignetteIntensity: Double?
    var countdownGlowRadius: Double?

    var backgroundImageUrl: String?
    var backgroundImageFit: String?
    var backgroundImageBlur: Double?

    var tickerBackgroundHex: String?
    var tickerTextHex: String?
    var tickerOpacity: Double?

    var cardBorderColorHex: String?
    var cardBorderOpacity: Double?
    var cardShadowDepth: Double?

    var countdownColorHex: String?
    var patternColorHex: String?

    static let empty = ThemeColorOverride()

    var hasOverrides: Bool {
        backgroundHex != nil || surfaceHex != nil || primaryHex != nil ||
        secondaryHex != nil || textPrimaryHex != nil || textSecondaryHex != nil ||
        accentHex != nil || adhanGlowHex != nil || gradientStop0Hex != nil ||
        gradientStop1Hex != nil || gradientStop2Hex != nil || gradientStop3Hex != nil ||
        patternOpacity != nil || vignetteIntensity != nil || countdownGlowRadius != nil ||
        backgroundImageUrl != nil || backgroundImageBlur != nil ||
        tickerBackgroundHex != nil || tickerTextHex != nil || tickerOpacity != nil ||
        cardBorderColorHex != nil || cardBorderOpacity != nil || cardShadowDepth != nil ||
        countdownColorHex != nil || patternColorHex != nil
    }
}

nonisolated struct ThemeCustomizationStore: Codable, Sendable {
    var overrides: [String: ThemeColorOverride]

    static let empty = ThemeCustomizationStore(overrides: [:])

    func override(for themeId: ThemeId) -> ThemeColorOverride {
        overrides[themeId.rawValue] ?? .empty
    }

    mutating func setOverride(_ override: ThemeColorOverride, for themeId: ThemeId) {
        overrides[themeId.rawValue] = override
    }

    mutating func resetOverride(for themeId: ThemeId) {
        overrides.removeValue(forKey: themeId.rawValue)
    }
}

extension Color {
    init?(hexString hex: String?) {
        guard let hex = hex, !hex.isEmpty else { return nil }
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }

    var toHexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension ThemeDefinition {
    func applying(override: ThemeColorOverride) -> ThemeDefinition {
        let newPalette = ThemePalette(
            background: Color(hexString: override.backgroundHex) ?? palette.background,
            surface: Color(hexString: override.surfaceHex) ?? palette.surface,
            primary: Color(hexString: override.primaryHex) ?? palette.primary,
            secondary: Color(hexString: override.secondaryHex) ?? palette.secondary,
            textPrimary: Color(hexString: override.textPrimaryHex) ?? palette.textPrimary,
            textSecondary: Color(hexString: override.textSecondaryHex) ?? palette.textSecondary,
            accent: Color(hexString: override.accentHex) ?? palette.accent,
            adhanGlow: Color(hexString: override.adhanGlowHex) ?? palette.adhanGlow
        )

        var newGradientStops = layers.gradientStops
        if let hex = override.gradientStop0Hex, let c = Color(hexString: hex), !newGradientStops.isEmpty {
            newGradientStops[0] = ThemeGradientStop(color: c, location: newGradientStops[0].location)
        }
        if let hex = override.gradientStop1Hex, let c = Color(hexString: hex), newGradientStops.count > 1 {
            newGradientStops[1] = ThemeGradientStop(color: c, location: newGradientStops[1].location)
        }
        if let hex = override.gradientStop2Hex, let c = Color(hexString: hex), newGradientStops.count > 2 {
            newGradientStops[2] = ThemeGradientStop(color: c, location: newGradientStops[2].location)
        }
        if let hex = override.gradientStop3Hex, let c = Color(hexString: hex), newGradientStops.count > 3 {
            newGradientStops[3] = ThemeGradientStop(color: c, location: newGradientStops[3].location)
        }

        let newLayers = ThemeLayerConfig(
            gradientStops: newGradientStops,
            gradientAngle: layers.gradientAngle,
            patternOpacity: CGFloat(override.patternOpacity ?? Double(layers.patternOpacity)),
            vignetteStyle: layers.vignetteStyle,
            vignetteIntensity: CGFloat(override.vignetteIntensity ?? Double(layers.vignetteIntensity)),
            glowStyle: layers.glowStyle,
            cardElevation: layers.cardElevation,
            cardBorderColor: layers.cardBorderColor,
            cardBorderOpacity: layers.cardBorderOpacity,
            cardShadowColor: layers.cardShadowColor,
            innerGlowColor: layers.innerGlowColor,
            hasShimmer: layers.hasShimmer,
            shimmerColor: layers.shimmerColor,
            shimmerSpeed: layers.shimmerSpeed,
            countdownGlowRadius: CGFloat(override.countdownGlowRadius ?? Double(layers.countdownGlowRadius)),
            tableRowSeparator: layers.tableRowSeparator,
            tableRowInset: layers.tableRowInset,
            tickerBackground: layers.tickerBackground,
            highlightShadowColor: layers.highlightShadowColor,
            neumorphicLightColor: layers.neumorphicLightColor
        )

        return ThemeDefinition(
            id: id,
            nameAr: nameAr,
            nameEn: nameEn,
            palette: newPalette,
            typography: typography,
            tokens: tokens,
            backgroundPattern: backgroundPattern,
            isDark: isDark,
            contrastRatio: contrastRatio,
            layers: newLayers
        )
    }
}
