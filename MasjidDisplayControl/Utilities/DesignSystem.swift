import SwiftUI
import SwiftUIX

enum DS {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    enum Elevation {
        static let low: CGFloat = 4
        static let medium: CGFloat = 8
        static let high: CGFloat = 16
        static let ultra: CGFloat = 24
    }
}

// MARK: - Premium Background

struct PremiumBackground: View {
    var accentColor: Color = .cyan
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DSTokens.Palette.backgroundMid,
                    DSTokens.Palette.backgroundDark,
                    Color(red: 0.03, green: 0.03, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showGlow {
                RadialGradient(
                    colors: [accentColor.opacity(0.04), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [accentColor.opacity(0.025), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Press Button Style

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? 2 : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.25, bounce: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Status Chip

struct StatusChip: View {
    let text: String
    let color: Color
    let icon: String?

    init(_ text: String, color: Color = .blue, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(DSTokens.Font.chipIcon)
            }
            Text(text)
                .font(DSTokens.Font.chipLabel)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
        }
        .frame(minWidth: 32)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(minWidth: DSTokens.ButtonSize.minTapTarget)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(.capsule)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(DSTokens.Font.sectionTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

// MARK: - Action Tile View

struct ActionTileView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: DSTokens.ButtonSize.tileIconSize, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(DSTokens.Font.tileTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(DSTokens.Font.tileSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 110)
        .glassLayer(.card)
    }
}

// MARK: - Radar Scan

struct RadarScanView: View {
    let color: Color
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 1)
            Circle().stroke(color.opacity(0.1), lineWidth: 1).scaleEffect(0.7)
            Circle().stroke(color.opacity(0.08), lineWidth: 1).scaleEffect(0.4)

            AngularGradient(
                gradient: Gradient(colors: [color.opacity(0.3), .clear]),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(90)
            )
            .rotationEffect(.degrees(rotation))
            .mask { Circle() }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Signal Strength

struct SignalStrengthView: View {
    let rssi: Int
    let color: Color

    private var bars: Int {
        if rssi >= -50 { return 4 }
        if rssi >= -65 { return 3 }
        if rssi >= -80 { return 2 }
        return 1
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { bar in
                RoundedRectangle(cornerRadius: 1)
                    .fill(bar <= bars ? color : color.opacity(0.2))
                    .frame(width: 3, height: CGFloat(bar) * 4 + 4)
            }
        }
    }
}

// MARK: - Theme Preview Thumbnail

struct ThemePreviewThumbnail: View {
    let theme: ThemeDefinition
    let showMiniRenderer: Bool

    init(theme: ThemeDefinition, showMiniRenderer: Bool = false) {
        self.theme = theme
        self.showMiniRenderer = showMiniRenderer
    }

    var body: some View {
        ZStack {
            if theme.layers.gradientStops.count >= 2 {
                LinearGradient(
                    stops: theme.layers.gradientStops.map { Gradient.Stop(color: $0.color, location: $0.location) },
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                theme.palette.background
            }

            IslamicPatternView(
                pattern: .minimal,
                color: theme.palette.primary,
                scaleFactor: 0.3,
                opacity: theme.layers.patternOpacity * 0.6
            )

            vignetteOverlay

            VStack(spacing: 8) {
                Text("12:30")
                    .font(.system(size: 32, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                    .foregroundStyle(theme.palette.textPrimary)
                    .shadow(color: theme.palette.primary.opacity(0.4), radius: theme.layers.countdownGlowRadius * 0.3)

                HStack(spacing: 14) {
                    ForEach([Prayer.fajr, .dhuhr, .asr, .maghrib, .isha], id: \.self) { prayer in
                        VStack(spacing: 2) {
                            Text(prayer.displayNameAr)
                                .font(.system(size: 8, weight: .medium, design: theme.typography.arabicFontDesign))
                            Text("12:00")
                                .font(.system(size: 9, weight: .semibold, design: theme.typography.timeFontDesign))
                                .monospacedDigit()
                        }
                        .foregroundStyle(prayer == .dhuhr ? theme.palette.accent : theme.palette.textPrimary.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.palette.surface.opacity(0.35))
                .clipShape(.rect(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(theme.palette.primary.opacity(0.15), lineWidth: 0.5)
                )
            }
        }
    }

    @ViewBuilder
    private var vignetteOverlay: some View {
        switch theme.layers.vignetteStyle {
        case .radialDark, .edgeBurn:
            RadialGradient(
                colors: [.clear, .black.opacity(theme.layers.vignetteIntensity * 0.3)],
                center: .center, startRadius: 30, endRadius: 120
            )
        case .radialLight:
            RadialGradient(
                colors: [.white.opacity(theme.layers.vignetteIntensity * 0.15), .clear],
                center: .center, startRadius: 0, endRadius: 100
            )
        case .bottomFade:
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, theme.palette.background.opacity(theme.layers.vignetteIntensity * 0.4)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 60)
            }
        default:
            Color.clear.frame(width: 0, height: 0)
        }
    }
}


