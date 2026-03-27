import SwiftUI

struct ThemePalette: Sendable {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let adhanGlow: Color
}

struct ThemeTypography: Sendable {
    let timeFontDesign: Font.Design
    let arabicFontDesign: Font.Design
    let latinFontDesign: Font.Design
    let timeWeight: Font.Weight
    let headingWeight: Font.Weight
}

nonisolated enum MarqueeDirection: String, Codable, Sendable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
}

struct ThemeTokens: Sendable {
    let cornerRadius: CGFloat
    let cardPadding: CGFloat
    let sectionSpacing: CGFloat
    let borderWidth: CGFloat
    let shadowRadius: CGFloat
    let minReadableFontSize: CGFloat
    let safeMargins: CGFloat
    let tableDensity: TableDensity
    let tickerDirection: MarqueeDirection
    let minFontScale: CGFloat
    let maxFontScale: CGFloat
}

nonisolated enum BackgroundPattern: Sendable {
    case geometricStars
    case arabesque
    case minimal
    case none
    case reliefStarfield
    case archMosaic
    case hexGrid
    case glassTile
    case ledMatrix
    case mosqueSilhouette
}

nonisolated enum VignetteStyle: Sendable {
    case none
    case radialDark
    case radialLight
    case topFade
    case bottomFade
    case edgeBurn
}

nonisolated enum GlowStyle: Sendable {
    case pulse
    case radialBurst
    case borderGlow
    case shimmerWave
    case neonFlicker
    case softBreath
}

nonisolated enum ElevationStyle: Sendable {
    case flat
    case raised
    case inset
    case floating
    case glassmorphic
    case neumorphic
}

struct ThemeGradientStop: Sendable {
    let color: Color
    let location: CGFloat
}

struct ThemeLayerConfig: Sendable {
    let gradientStops: [ThemeGradientStop]
    let gradientAngle: Double
    let patternOpacity: CGFloat
    let vignetteStyle: VignetteStyle
    let vignetteIntensity: CGFloat
    let glowStyle: GlowStyle
    let cardElevation: ElevationStyle
    let cardBorderColor: Color?
    let cardBorderOpacity: CGFloat
    let cardShadowColor: Color
    let innerGlowColor: Color?
    let hasShimmer: Bool
    let shimmerColor: Color
    let shimmerSpeed: Double
    let countdownGlowRadius: CGFloat
    let tableRowSeparator: Bool
    let tableRowInset: Bool
    let tickerBackground: Color?
    let highlightShadowColor: Color?
    let neumorphicLightColor: Color?

    static let `default` = ThemeLayerConfig(
        gradientStops: [],
        gradientAngle: 180,
        patternOpacity: 0.08,
        vignetteStyle: .none,
        vignetteIntensity: 0.4,
        glowStyle: .pulse,
        cardElevation: .raised,
        cardBorderColor: nil,
        cardBorderOpacity: 0,
        cardShadowColor: .black.opacity(0.2),
        innerGlowColor: nil,
        hasShimmer: false,
        shimmerColor: .white.opacity(0.08),
        shimmerSpeed: 3.0,
        countdownGlowRadius: 12,
        tableRowSeparator: false,
        tableRowInset: false,
        tickerBackground: nil,
        highlightShadowColor: nil,
        neumorphicLightColor: nil
    )
}

struct ThemeDefinition: Identifiable, Sendable {
    let id: ThemeId
    let nameAr: String
    let nameEn: String
    let palette: ThemePalette
    let typography: ThemeTypography
    let tokens: ThemeTokens
    let backgroundPattern: BackgroundPattern
    let isDark: Bool
    let contrastRatio: Double
    let layers: ThemeLayerConfig

    static let allThemes: [ThemeDefinition] = [
        .islamicGeoDark,
        .ottomanClassic,
        .minimalNoor,
        .ledMosque,
        .islamicRelief,
        .ottomanGoldNight,
        .modernArchDepth,
        .smartGlass,
        .ledDigitalPremium,
        .skySilhouette,
    ]

    static func theme(for id: ThemeId) -> ThemeDefinition {
        allThemes.first { $0.id == id } ?? .islamicGeoDark
    }

    // MARK: - Original Themes (preserved)

    static let islamicGeoDark = ThemeDefinition(
        id: .islamicGeoDark,
        nameAr: "هندسي إسلامي داكن",
        nameEn: "Islamic Geometric Dark",
        palette: ThemePalette(
            background: Color(red: 0.07, green: 0.07, blue: 0.14),
            surface: Color(red: 0.12, green: 0.12, blue: 0.2),
            primary: Color(red: 0.85, green: 0.68, blue: 0.32),
            secondary: Color(red: 0.6, green: 0.5, blue: 0.3),
            textPrimary: Color(red: 0.95, green: 0.93, blue: 0.88),
            textSecondary: Color(red: 0.7, green: 0.68, blue: 0.62),
            accent: Color(red: 0.85, green: 0.68, blue: 0.32),
            adhanGlow: Color(red: 0.85, green: 0.68, blue: 0.32).opacity(0.3)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .serif, latinFontDesign: .default, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 16, cardPadding: 16, sectionSpacing: 12, borderWidth: 1, shadowRadius: 8, minReadableFontSize: 11, safeMargins: 20, tableDensity: .comfortable, tickerDirection: .leftToRight, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .geometricStars,
        isDark: true,
        contrastRatio: 7.5,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.04, green: 0.04, blue: 0.10), location: 0),
                ThemeGradientStop(color: Color(red: 0.09, green: 0.09, blue: 0.18), location: 0.45),
                ThemeGradientStop(color: Color(red: 0.06, green: 0.06, blue: 0.13), location: 0.8),
                ThemeGradientStop(color: Color(red: 0.03, green: 0.03, blue: 0.08), location: 1.0),
            ],
            gradientAngle: 175,
            patternOpacity: 0.10,
            vignetteStyle: .radialDark,
            vignetteIntensity: 0.4,
            glowStyle: .pulse,
            cardElevation: .raised,
            cardBorderColor: Color(red: 0.85, green: 0.68, blue: 0.32),
            cardBorderOpacity: 0.15,
            cardShadowColor: .black.opacity(0.3),
            innerGlowColor: Color(red: 0.85, green: 0.68, blue: 0.32).opacity(0.05),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.06),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 14,
            tableRowSeparator: true,
            tableRowInset: false,
            tickerBackground: Color(red: 0.85, green: 0.68, blue: 0.32).opacity(0.06),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    static let ottomanClassic = ThemeDefinition(
        id: .ottomanClassic,
        nameAr: "عثماني كلاسيكي",
        nameEn: "Ottoman Classic",
        palette: ThemePalette(
            background: Color(red: 0.06, green: 0.22, blue: 0.18),
            surface: Color(red: 0.08, green: 0.28, blue: 0.23),
            primary: Color(red: 0.96, green: 0.93, blue: 0.84),
            secondary: Color(red: 0.78, green: 0.72, blue: 0.58),
            textPrimary: Color(red: 0.96, green: 0.93, blue: 0.84),
            textSecondary: Color(red: 0.78, green: 0.72, blue: 0.58),
            accent: Color(red: 0.85, green: 0.75, blue: 0.45),
            adhanGlow: Color(red: 0.85, green: 0.75, blue: 0.45).opacity(0.3)
        ),
        typography: ThemeTypography(timeFontDesign: .serif, arabicFontDesign: .serif, latinFontDesign: .serif, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 12, cardPadding: 16, sectionSpacing: 12, borderWidth: 2, shadowRadius: 4, minReadableFontSize: 11, safeMargins: 20, tableDensity: .comfortable, tickerDirection: .leftToRight, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .arabesque,
        isDark: true,
        contrastRatio: 7.2,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.04, green: 0.18, blue: 0.14), location: 0),
                ThemeGradientStop(color: Color(red: 0.07, green: 0.25, blue: 0.20), location: 0.4),
                ThemeGradientStop(color: Color(red: 0.05, green: 0.20, blue: 0.16), location: 0.75),
                ThemeGradientStop(color: Color(red: 0.03, green: 0.14, blue: 0.10), location: 1.0),
            ],
            gradientAngle: 170,
            patternOpacity: 0.10,
            vignetteStyle: .edgeBurn,
            vignetteIntensity: 0.4,
            glowStyle: .softBreath,
            cardElevation: .floating,
            cardBorderColor: Color(red: 0.85, green: 0.75, blue: 0.45),
            cardBorderOpacity: 0.18,
            cardShadowColor: .black.opacity(0.25),
            innerGlowColor: Color(red: 0.85, green: 0.75, blue: 0.45).opacity(0.06),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.05),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 12,
            tableRowSeparator: true,
            tableRowInset: true,
            tickerBackground: Color(red: 0.85, green: 0.75, blue: 0.45).opacity(0.06),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    static let minimalNoor = ThemeDefinition(
        id: .minimalNoor,
        nameAr: "نور بسيط",
        nameEn: "Minimal Noor",
        palette: ThemePalette(
            background: Color(red: 0.96, green: 0.95, blue: 0.92),
            surface: Color.white,
            primary: Color(red: 0.2, green: 0.4, blue: 0.5),
            secondary: Color(red: 0.5, green: 0.6, blue: 0.65),
            textPrimary: Color(red: 0.15, green: 0.15, blue: 0.2),
            textSecondary: Color(red: 0.45, green: 0.45, blue: 0.5),
            accent: Color(red: 0.2, green: 0.55, blue: 0.55),
            adhanGlow: Color(red: 0.2, green: 0.55, blue: 0.55).opacity(0.2)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .default, latinFontDesign: .default, timeWeight: .semibold, headingWeight: .medium),
        tokens: ThemeTokens(cornerRadius: 20, cardPadding: 20, sectionSpacing: 16, borderWidth: 0, shadowRadius: 12, minReadableFontSize: 12, safeMargins: 24, tableDensity: .comfortable, tickerDirection: .leftToRight, minFontScale: 0.6, maxFontScale: 1.3),
        backgroundPattern: .minimal,
        isDark: false,
        contrastRatio: 8.1,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.97, green: 0.96, blue: 0.93), location: 0),
                ThemeGradientStop(color: Color(red: 0.94, green: 0.93, blue: 0.90), location: 0.5),
                ThemeGradientStop(color: Color(red: 0.96, green: 0.95, blue: 0.92), location: 1.0),
            ],
            gradientAngle: 160,
            patternOpacity: 0.05,
            vignetteStyle: .radialLight,
            vignetteIntensity: 0.12,
            glowStyle: .softBreath,
            cardElevation: .raised,
            cardBorderColor: nil,
            cardBorderOpacity: 0,
            cardShadowColor: Color(red: 0.2, green: 0.4, blue: 0.5).opacity(0.10),
            innerGlowColor: Color.white.opacity(0.6),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.08),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 10,
            tableRowSeparator: true,
            tableRowInset: false,
            tickerBackground: Color(red: 0.2, green: 0.55, blue: 0.55).opacity(0.06),
            highlightShadowColor: Color.white.opacity(0.5),
            neumorphicLightColor: nil
        )
    )

    static let ledMosque = ThemeDefinition(
        id: .ledMosque,
        nameAr: "شاشة LED",
        nameEn: "LED Mosque",
        palette: ThemePalette(
            background: Color.black,
            surface: Color(red: 0.06, green: 0.06, blue: 0.06),
            primary: Color(red: 0.0, green: 1.0, blue: 0.4),
            secondary: Color(red: 0.0, green: 0.7, blue: 0.3),
            textPrimary: Color(red: 0.0, green: 1.0, blue: 0.4),
            textSecondary: Color(red: 0.0, green: 0.6, blue: 0.25),
            accent: Color(red: 1.0, green: 0.3, blue: 0.1),
            adhanGlow: Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.3)
        ),
        typography: ThemeTypography(timeFontDesign: .monospaced, arabicFontDesign: .monospaced, latinFontDesign: .monospaced, timeWeight: .bold, headingWeight: .bold),
        tokens: ThemeTokens(cornerRadius: 4, cardPadding: 12, sectionSpacing: 8, borderWidth: 1, shadowRadius: 0, minReadableFontSize: 10, safeMargins: 12, tableDensity: .compact, tickerDirection: .leftToRight, minFontScale: 0.5, maxFontScale: 1.4),
        backgroundPattern: .none,
        isDark: true,
        contrastRatio: 15.0,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color.black, location: 0),
                ThemeGradientStop(color: Color(red: 0.03, green: 0.03, blue: 0.03), location: 0.5),
                ThemeGradientStop(color: Color.black, location: 1.0),
            ],
            gradientAngle: 180,
            patternOpacity: 0.0,
            vignetteStyle: .edgeBurn,
            vignetteIntensity: 0.5,
            glowStyle: .neonFlicker,
            cardElevation: .inset,
            cardBorderColor: Color(red: 0.0, green: 1.0, blue: 0.4),
            cardBorderOpacity: 0.20,
            cardShadowColor: .black.opacity(0.5),
            innerGlowColor: Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.03),
            hasShimmer: false,
            shimmerColor: Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.04),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 8,
            tableRowSeparator: false,
            tableRowInset: false,
            tickerBackground: Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.04),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    // MARK: - New Premium Themes

    // 1) Islamic Relief Layered — Paper-cut depth, soft shadows, carved geometric rosettes
    static let islamicRelief = ThemeDefinition(
        id: .islamicRelief,
        nameAr: "نقش إسلامي بارز",
        nameEn: "Islamic Relief Layered",
        palette: ThemePalette(
            background: Color(red: 0.92, green: 0.91, blue: 0.89),   // #EAE8E3 warm parchment
            surface: Color(red: 0.97, green: 0.96, blue: 0.94),       // #F8F5F0 raised card
            primary: Color(red: 0.55, green: 0.52, blue: 0.50),       // #8C8580 stone gray
            secondary: Color(red: 0.72, green: 0.60, blue: 0.56),     // #B8998F dusty rose
            textPrimary: Color(red: 0.18, green: 0.16, blue: 0.15),   // #2E2926 dark walnut
            textSecondary: Color(red: 0.50, green: 0.47, blue: 0.44), // #807870
            accent: Color(red: 0.72, green: 0.55, blue: 0.44),        // #B88C70 terracotta
            adhanGlow: Color(red: 0.72, green: 0.55, blue: 0.44).opacity(0.25)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .serif, latinFontDesign: .default, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 20, cardPadding: 20, sectionSpacing: 14, borderWidth: 0, shadowRadius: 16, minReadableFontSize: 11, safeMargins: 24, tableDensity: .comfortable, tickerDirection: .rightToLeft, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .reliefStarfield,
        isDark: false,
        contrastRatio: 8.5,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.95, green: 0.93, blue: 0.91), location: 0),
                ThemeGradientStop(color: Color(red: 0.88, green: 0.86, blue: 0.83), location: 0.6),
                ThemeGradientStop(color: Color(red: 0.82, green: 0.80, blue: 0.77), location: 1.0),
            ],
            gradientAngle: 160,
            patternOpacity: 0.12,
            vignetteStyle: .radialLight,
            vignetteIntensity: 0.15,
            glowStyle: .softBreath,
            cardElevation: .raised,
            cardBorderColor: nil,
            cardBorderOpacity: 0,
            cardShadowColor: Color(red: 0.55, green: 0.52, blue: 0.50).opacity(0.18),
            innerGlowColor: Color.white.opacity(0.5),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.06),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 8,
            tableRowSeparator: true,
            tableRowInset: false,
            tickerBackground: Color(red: 0.72, green: 0.55, blue: 0.44).opacity(0.08),
            highlightShadowColor: Color.white.opacity(0.6),
            neumorphicLightColor: nil
        )
    )

    // 2) Ottoman Gold Night — Royal blue with gold calligraphy arches, luxury depth
    static let ottomanGoldNight = ThemeDefinition(
        id: .ottomanGoldNight,
        nameAr: "ليل عثماني ذهبي",
        nameEn: "Ottoman Gold Night",
        palette: ThemePalette(
            background: Color(red: 0.05, green: 0.08, blue: 0.20),    // #0D1433 midnight blue
            surface: Color(red: 0.08, green: 0.12, blue: 0.28),       // #141F47 raised surface
            primary: Color(red: 0.85, green: 0.72, blue: 0.38),       // #D9B861 warm gold
            secondary: Color(red: 0.70, green: 0.62, blue: 0.45),     // #B39E73 antique gold
            textPrimary: Color(red: 0.95, green: 0.92, blue: 0.85),   // #F2EBD9 warm white
            textSecondary: Color(red: 0.68, green: 0.64, blue: 0.55), // #ADA38C muted gold
            accent: Color(red: 0.92, green: 0.78, blue: 0.35),        // #EBC759 bright gold
            adhanGlow: Color(red: 0.92, green: 0.78, blue: 0.35).opacity(0.35)
        ),
        typography: ThemeTypography(timeFontDesign: .serif, arabicFontDesign: .serif, latinFontDesign: .serif, timeWeight: .bold, headingWeight: .bold),
        tokens: ThemeTokens(cornerRadius: 14, cardPadding: 18, sectionSpacing: 14, borderWidth: 1.5, shadowRadius: 12, minReadableFontSize: 11, safeMargins: 22, tableDensity: .comfortable, tickerDirection: .rightToLeft, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .archMosaic,
        isDark: true,
        contrastRatio: 8.0,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.04, green: 0.06, blue: 0.16), location: 0),
                ThemeGradientStop(color: Color(red: 0.07, green: 0.10, blue: 0.26), location: 0.4),
                ThemeGradientStop(color: Color(red: 0.05, green: 0.08, blue: 0.22), location: 0.8),
                ThemeGradientStop(color: Color(red: 0.03, green: 0.04, blue: 0.12), location: 1.0),
            ],
            gradientAngle: 170,
            patternOpacity: 0.10,
            vignetteStyle: .edgeBurn,
            vignetteIntensity: 0.5,
            glowStyle: .radialBurst,
            cardElevation: .floating,
            cardBorderColor: Color(red: 0.85, green: 0.72, blue: 0.38),
            cardBorderOpacity: 0.25,
            cardShadowColor: Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.15),
            innerGlowColor: Color(red: 0.92, green: 0.78, blue: 0.35).opacity(0.08),
            hasShimmer: true,
            shimmerColor: Color(red: 0.92, green: 0.78, blue: 0.35).opacity(0.06),
            shimmerSpeed: 4.0,
            countdownGlowRadius: 18,
            tableRowSeparator: true,
            tableRowInset: true,
            tickerBackground: Color(red: 0.85, green: 0.72, blue: 0.38).opacity(0.08),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    // 3) Modern Architectural Depth — 3D hex geometry, charcoal with olive/orange accents
    static let modernArchDepth = ThemeDefinition(
        id: .modernArchDepth,
        nameAr: "عمق معماري حديث",
        nameEn: "Modern Architectural Depth",
        palette: ThemePalette(
            background: Color(red: 0.11, green: 0.11, blue: 0.12),    // #1C1C1E charcoal
            surface: Color(red: 0.16, green: 0.16, blue: 0.17),       // #292929 raised
            primary: Color(red: 0.60, green: 0.58, blue: 0.38),       // #999461 olive
            secondary: Color(red: 0.82, green: 0.52, blue: 0.22),     // #D18538 warm orange
            textPrimary: Color(red: 0.92, green: 0.91, blue: 0.89),   // #EAE8E3
            textSecondary: Color(red: 0.62, green: 0.60, blue: 0.58), // #9E9994
            accent: Color(red: 0.88, green: 0.55, blue: 0.18),        // #E08C2E amber
            adhanGlow: Color(red: 0.88, green: 0.55, blue: 0.18).opacity(0.30)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .default, latinFontDesign: .default, timeWeight: .heavy, headingWeight: .bold),
        tokens: ThemeTokens(cornerRadius: 10, cardPadding: 16, sectionSpacing: 12, borderWidth: 0, shadowRadius: 12, minReadableFontSize: 11, safeMargins: 20, tableDensity: .comfortable, tickerDirection: .leftToRight, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .hexGrid,
        isDark: true,
        contrastRatio: 7.8,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.08, green: 0.08, blue: 0.09), location: 0),
                ThemeGradientStop(color: Color(red: 0.13, green: 0.13, blue: 0.14), location: 0.5),
                ThemeGradientStop(color: Color(red: 0.09, green: 0.09, blue: 0.10), location: 1.0),
            ],
            gradientAngle: 135,
            patternOpacity: 0.06,
            vignetteStyle: .radialDark,
            vignetteIntensity: 0.35,
            glowStyle: .borderGlow,
            cardElevation: .neumorphic,
            cardBorderColor: nil,
            cardBorderOpacity: 0,
            cardShadowColor: .black.opacity(0.4),
            innerGlowColor: Color(red: 0.60, green: 0.58, blue: 0.38).opacity(0.05),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.04),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 14,
            tableRowSeparator: false,
            tableRowInset: false,
            tickerBackground: Color(red: 0.60, green: 0.58, blue: 0.38).opacity(0.06),
            highlightShadowColor: nil,
            neumorphicLightColor: Color(red: 0.22, green: 0.22, blue: 0.24)
        )
    )

    // 4) Smart Glass Mosque — Frosted glass panels on dark gradient, translucent depth
    static let smartGlass = ThemeDefinition(
        id: .smartGlass,
        nameAr: "زجاج ذكي",
        nameEn: "Smart Glass Mosque",
        palette: ThemePalette(
            background: Color(red: 0.08, green: 0.08, blue: 0.10),    // #141419 near-black
            surface: Color(red: 0.18, green: 0.18, blue: 0.22),       // #2E2E38 glass
            primary: Color(red: 0.78, green: 0.70, blue: 0.55),       // #C7B38C warm champagne
            secondary: Color(red: 0.55, green: 0.52, blue: 0.48),     // #8C857A
            textPrimary: Color(red: 0.95, green: 0.94, blue: 0.92),   // #F2F0EB
            textSecondary: Color(red: 0.65, green: 0.63, blue: 0.60), // #A6A099
            accent: Color(red: 0.88, green: 0.72, blue: 0.42),        // #E0B86B gold
            adhanGlow: Color(red: 0.88, green: 0.72, blue: 0.42).opacity(0.28)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .serif, latinFontDesign: .default, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 18, cardPadding: 18, sectionSpacing: 14, borderWidth: 1, shadowRadius: 16, minReadableFontSize: 11, safeMargins: 22, tableDensity: .comfortable, tickerDirection: .rightToLeft, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .glassTile,
        isDark: true,
        contrastRatio: 7.6,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.06, green: 0.06, blue: 0.08), location: 0),
                ThemeGradientStop(color: Color(red: 0.10, green: 0.10, blue: 0.14), location: 0.3),
                ThemeGradientStop(color: Color(red: 0.08, green: 0.08, blue: 0.12), location: 0.7),
                ThemeGradientStop(color: Color(red: 0.05, green: 0.05, blue: 0.07), location: 1.0),
            ],
            gradientAngle: 200,
            patternOpacity: 0.04,
            vignetteStyle: .radialDark,
            vignetteIntensity: 0.3,
            glowStyle: .shimmerWave,
            cardElevation: .glassmorphic,
            cardBorderColor: Color.white,
            cardBorderOpacity: 0.12,
            cardShadowColor: .black.opacity(0.35),
            innerGlowColor: Color.white.opacity(0.04),
            hasShimmer: true,
            shimmerColor: Color.white.opacity(0.06),
            shimmerSpeed: 5.0,
            countdownGlowRadius: 20,
            tableRowSeparator: true,
            tableRowInset: true,
            tickerBackground: Color.white.opacity(0.04),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    // 5) LED Digital Premium — Dark neumorphic with warm coral/salmon digit glow
    static let ledDigitalPremium = ThemeDefinition(
        id: .ledDigitalPremium,
        nameAr: "شاشة رقمية فاخرة",
        nameEn: "LED Digital Premium",
        palette: ThemePalette(
            background: Color(red: 0.10, green: 0.10, blue: 0.11),    // #1A1A1C deep dark
            surface: Color(red: 0.14, green: 0.14, blue: 0.15),       // #242426 inset
            primary: Color(red: 0.95, green: 0.60, blue: 0.48),       // #F29A7A coral
            secondary: Color(red: 0.70, green: 0.45, blue: 0.38),     // #B37361
            textPrimary: Color(red: 0.92, green: 0.90, blue: 0.88),   // #EAE6E0
            textSecondary: Color(red: 0.55, green: 0.53, blue: 0.51), // #8C8882
            accent: Color(red: 0.98, green: 0.52, blue: 0.40),        // #FA8566 warm coral
            adhanGlow: Color(red: 0.98, green: 0.52, blue: 0.40).opacity(0.30)
        ),
        typography: ThemeTypography(timeFontDesign: .monospaced, arabicFontDesign: .default, latinFontDesign: .monospaced, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 16, cardPadding: 16, sectionSpacing: 10, borderWidth: 0, shadowRadius: 6, minReadableFontSize: 11, safeMargins: 18, tableDensity: .compact, tickerDirection: .leftToRight, minFontScale: 0.5, maxFontScale: 1.4),
        backgroundPattern: .ledMatrix,
        isDark: true,
        contrastRatio: 8.2,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.08, green: 0.08, blue: 0.09), location: 0),
                ThemeGradientStop(color: Color(red: 0.12, green: 0.12, blue: 0.13), location: 0.5),
                ThemeGradientStop(color: Color(red: 0.08, green: 0.08, blue: 0.09), location: 1.0),
            ],
            gradientAngle: 180,
            patternOpacity: 0.03,
            vignetteStyle: .edgeBurn,
            vignetteIntensity: 0.4,
            glowStyle: .neonFlicker,
            cardElevation: .inset,
            cardBorderColor: Color(red: 0.25, green: 0.25, blue: 0.27),
            cardBorderOpacity: 0.5,
            cardShadowColor: .black.opacity(0.5),
            innerGlowColor: Color(red: 0.95, green: 0.60, blue: 0.48).opacity(0.03),
            hasShimmer: false,
            shimmerColor: .white.opacity(0.03),
            shimmerSpeed: 3.0,
            countdownGlowRadius: 10,
            tableRowSeparator: false,
            tableRowInset: false,
            tickerBackground: Color(red: 0.95, green: 0.60, blue: 0.48).opacity(0.04),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )

    // 6) Sky Silhouette Gradient — Mosque skyline over time-of-day gradient
    static let skySilhouette = ThemeDefinition(
        id: .skySilhouette,
        nameAr: "ظلال السماء",
        nameEn: "Sky Silhouette Gradient",
        palette: ThemePalette(
            background: Color(red: 0.10, green: 0.08, blue: 0.22),    // #1A1438 night indigo
            surface: Color(red: 0.14, green: 0.12, blue: 0.28),       // #241E47 panel
            primary: Color(red: 0.70, green: 0.60, blue: 0.90),       // #B399E5 lavender
            secondary: Color(red: 0.88, green: 0.62, blue: 0.50),     // #E09E80 sunset peach
            textPrimary: Color(red: 0.96, green: 0.95, blue: 0.98),   // #F5F2FA
            textSecondary: Color(red: 0.72, green: 0.68, blue: 0.78), // #B8ADC7
            accent: Color(red: 0.95, green: 0.72, blue: 0.40),        // #F2B866 sunset gold
            adhanGlow: Color(red: 0.95, green: 0.72, blue: 0.40).opacity(0.30)
        ),
        typography: ThemeTypography(timeFontDesign: .default, arabicFontDesign: .serif, latinFontDesign: .default, timeWeight: .bold, headingWeight: .semibold),
        tokens: ThemeTokens(cornerRadius: 16, cardPadding: 16, sectionSpacing: 12, borderWidth: 0, shadowRadius: 10, minReadableFontSize: 11, safeMargins: 20, tableDensity: .comfortable, tickerDirection: .leftToRight, minFontScale: 0.55, maxFontScale: 1.35),
        backgroundPattern: .mosqueSilhouette,
        isDark: true,
        contrastRatio: 7.4,
        layers: ThemeLayerConfig(
            gradientStops: [
                ThemeGradientStop(color: Color(red: 0.08, green: 0.06, blue: 0.18), location: 0),
                ThemeGradientStop(color: Color(red: 0.15, green: 0.10, blue: 0.32), location: 0.3),
                ThemeGradientStop(color: Color(red: 0.35, green: 0.18, blue: 0.35), location: 0.6),
                ThemeGradientStop(color: Color(red: 0.55, green: 0.30, blue: 0.28), location: 0.8),
                ThemeGradientStop(color: Color(red: 0.12, green: 0.08, blue: 0.20), location: 1.0),
            ],
            gradientAngle: 180,
            patternOpacity: 0.15,
            vignetteStyle: .bottomFade,
            vignetteIntensity: 0.5,
            glowStyle: .radialBurst,
            cardElevation: .floating,
            cardBorderColor: nil,
            cardBorderOpacity: 0,
            cardShadowColor: .black.opacity(0.3),
            innerGlowColor: Color(red: 0.70, green: 0.60, blue: 0.90).opacity(0.06),
            hasShimmer: true,
            shimmerColor: Color(red: 0.95, green: 0.72, blue: 0.40).opacity(0.05),
            shimmerSpeed: 6.0,
            countdownGlowRadius: 16,
            tableRowSeparator: true,
            tableRowInset: true,
            tickerBackground: Color(red: 0.70, green: 0.60, blue: 0.90).opacity(0.08),
            highlightShadowColor: nil,
            neumorphicLightColor: nil
        )
    )
}
