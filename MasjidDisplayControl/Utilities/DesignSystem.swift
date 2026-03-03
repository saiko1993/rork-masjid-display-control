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

// MARK: - Premium Background V2

struct PremiumBackground: View {
    var accentColor: Color = .cyan
    var showGlow: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.10),
                    Color(red: 0.03, green: 0.03, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showGlow {
                RadialGradient(
                    colors: [accentColor.opacity(0.07), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [accentColor.opacity(0.04), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Glass Panel (SwiftUIX VisualEffectBlurView)

struct GlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tintColor: Color = .white
    var blurStyle: UIBlurEffect.Style = .systemThinMaterialDark

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    VisualEffectBlurView(blurStyle: blurStyle)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tintColor.opacity(0.08), .clear, tintColor.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tintColor.opacity(0.2), tintColor.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 20, tint: Color = .white, blurStyle: UIBlurEffect.Style = .systemThinMaterialDark) -> some View {
        modifier(GlassPanelModifier(cornerRadius: cornerRadius, tintColor: tint, blurStyle: blurStyle))
    }
}

// MARK: - Glow Glass Panel (SwiftUIX)

struct GlowGlassPanelModifier: ViewModifier {
    var glowColor: Color = .cyan
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    VisualEffectBlurView(blurStyle: .systemThinMaterialDark)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [glowColor.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [glowColor.opacity(0.3), glowColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: glowColor.opacity(0.15), radius: 16, y: 6)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

extension View {
    func glowGlassPanel(color: Color = .cyan, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlowGlassPanelModifier(glowColor: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Card Modifier V2

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var tintColor: Color = .white

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tintColor.opacity(0.06), .clear, tintColor.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tintColor.opacity(0.18), tintColor.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, tint: Color = .white) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, tintColor: tint))
    }
}

// MARK: - Glow Glass Card

struct GlowGlassModifier: ViewModifier {
    var glowColor: Color = .cyan
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [glowColor.opacity(0.08), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [glowColor.opacity(0.25), glowColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: glowColor.opacity(0.12), radius: 16, y: 6)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

extension View {
    func glowGlass(color: Color = .cyan, cornerRadius: CGFloat = 20) -> some View {
        modifier(GlowGlassModifier(glowColor: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Button Style

struct GradientButtonStyle: ButtonStyle {
    var colors: [Color] = [.cyan, .blue]
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
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
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(.capsule)
    }
}

// MARK: - Section Header V2

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
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Hero Section

struct HeroGlassView: View {
    let title: String
    let subtitle: String
    let icon: String
    var accentColor: Color = .cyan
    var showPulse: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [accentColor.opacity(0.1), .clear, accentColor.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))

            RadialGradient(
                colors: [accentColor.opacity(0.12), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 180
            )
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))

            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(accentColor)
                    .symbolEffect(.pulse.byLayer, options: showPulse ? .repeating : .default)

                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 150)
        .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [accentColor.opacity(0.2), accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: accentColor.opacity(0.12), radius: 20, y: 8)
    }
}

// MARK: - Action Tile Button

struct ActionTileView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 110)
        .glassCard(cornerRadius: DS.Radius.xl)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: max(0, phase - 0.15)),
                        .init(color: .white.opacity(0.05), location: phase),
                        .init(color: .clear, location: min(1, phase + 0.15)),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(.rect(cornerRadius: DS.Radius.xl, style: .continuous))
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Pulse Ring

struct PulseRingView: View {
    let color: Color
    let isAnimating: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                guard isAnimating else { return }
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 1.8
                    opacity = 0
                }
            }
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

// MARK: - Backward Compat: ThemedBackground (used by DisplayRendererView)

struct ThemedBackground: View {
    let theme: ThemeDefinition

    var body: some View {
        ZStack {
            if theme.layers.gradientStops.count >= 2 {
                LinearGradient(
                    stops: theme.layers.gradientStops.map { Gradient.Stop(color: $0.color, location: $0.location) },
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                theme.palette.background
                    .ignoresSafeArea()
            }

            IslamicPatternView(
                pattern: theme.backgroundPattern,
                color: theme.palette.primary,
                scaleFactor: 0.35,
                opacity: theme.layers.patternOpacity * 0.5
            )
            .ignoresSafeArea()

            vignetteOverlay
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    theme.palette.accent.opacity(0.03),
                    .clear,
                    .clear,
                    theme.palette.background.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var vignetteOverlay: some View {
        switch theme.layers.vignetteStyle {
        case .radialDark:
            RadialGradient(
                colors: [.clear, .black.opacity(theme.layers.vignetteIntensity * 0.35)],
                center: .center, startRadius: 100, endRadius: 500
            )
        case .edgeBurn:
            RadialGradient(
                colors: [.clear, .black.opacity(theme.layers.vignetteIntensity * 0.25)],
                center: .center, startRadius: 150, endRadius: 600
            )
        case .radialLight:
            RadialGradient(
                colors: [.white.opacity(theme.layers.vignetteIntensity * 0.15), .clear],
                center: .center, startRadius: 0, endRadius: 400
            )
        case .bottomFade:
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, theme.palette.background.opacity(theme.layers.vignetteIntensity * 0.3)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 300)
            }
        default:
            Color.clear.frame(width: 0, height: 0)
        }
    }
}

// MARK: - Backward Compat: ThemedPageBackground (used by ThemesView, ThemeDetailView, DocsView)

struct ThemedPageBackground: View {
    let theme: ThemeDefinition
    let accentGlow: Bool

    init(theme: ThemeDefinition, accentGlow: Bool = false) {
        self.theme = theme
        self.accentGlow = accentGlow
    }

    var body: some View {
        PremiumBackground(accentColor: theme.palette.accent, showGlow: accentGlow)
    }
}

// MARK: - Backward Compat: GlassCard (used by DisplayRendererView)

struct GlassCard<Content: View>: View {
    let theme: ThemeDefinition
    let cornerRadius: CGFloat
    let content: () -> Content

    init(theme: ThemeDefinition, cornerRadius: CGFloat = DS.Radius.xl, @ViewBuilder content: @escaping () -> Content) {
        self.theme = theme
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.Spacing.md)
            .background {
                switch theme.layers.cardElevation {
                case .glassmorphic:
                    ZStack {
                        theme.palette.surface.opacity(0.35)
                        if let glow = theme.layers.innerGlowColor {
                            LinearGradient(colors: [glow, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                case .neumorphic:
                    theme.palette.surface
                case .floating:
                    ZStack {
                        theme.palette.surface.opacity(0.55)
                        if let glow = theme.layers.innerGlowColor { glow }
                    }
                case .raised:
                    ZStack {
                        theme.palette.surface.opacity(0.5)
                        if let highlight = theme.layers.highlightShadowColor {
                            LinearGradient(colors: [highlight.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        }
                    }
                case .inset:
                    ZStack {
                        theme.palette.surface.opacity(0.6)
                        LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom)
                    }
                case .flat:
                    theme.palette.surface.opacity(0.3)
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                Group {
                    if let borderColor = theme.layers.cardBorderColor, theme.layers.cardBorderOpacity > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderColor.opacity(theme.layers.cardBorderOpacity), lineWidth: theme.tokens.borderWidth)
                    }
                }
            )
            .shadow(color: theme.layers.cardShadowColor, radius: theme.tokens.shadowRadius, y: 4)
    }
}

// MARK: - Backward Compat: premiumCard, card3D, accentGlowCard

struct PremiumCardStyle: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glassCard(cornerRadius: cornerRadius)
    }
}

extension View {
    func premiumCard(cornerRadius: CGFloat = DS.Radius.xl) -> some View {
        modifier(PremiumCardStyle(cornerRadius: cornerRadius))
    }
}

struct AccentGlowCard: ViewModifier {
    let accentColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glowGlass(color: accentColor, cornerRadius: cornerRadius)
    }
}

extension View {
    func accentGlowCard(color: Color, cornerRadius: CGFloat = DS.Radius.xl) -> some View {
        modifier(AccentGlowCard(accentColor: color, cornerRadius: cornerRadius))
    }
}

struct Card3DStyle: ViewModifier {
    let depth: CGFloat
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .glowGlass(color: accentColor, cornerRadius: DS.Radius.xl)
    }
}

extension View {
    func card3D(depth: CGFloat = 8, accent: Color = .blue) -> some View {
        modifier(Card3DStyle(depth: depth, accentColor: accent))
    }
}

// MARK: - Connection Status Animation View

struct ConnectionPulseView: View {
    let isConnected: Bool
    let color: Color
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            if isConnected {
                Circle()
                    .fill(color.opacity(0.15))
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .opacity(pulse ? 0 : 0.6)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.4), radius: isConnected ? 12 : 4)
        }
        .onAppear {
            if isConnected { pulse = true }
        }
        .onChange(of: isConnected) { _, newValue in
            pulse = newValue
        }
    }
}

// MARK: - Backward Compat: LightSweepEffect

struct LightSweepEffect: ViewModifier {
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { _ in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.15)),
                            .init(color: .white.opacity(0.07), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.15)),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(.rect(cornerRadius: DS.Radius.xl, style: .continuous))
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func lightSweep() -> some View {
        modifier(LightSweepEffect())
    }
}

// MARK: - Backward Compat: IslamicHeaderView

struct IslamicHeaderView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse.byLayer)
            Text(title)
                .font(.title2.bold())
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
    }
}

// MARK: - Backward Compat: ActionCardView

struct ActionCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    init(icon: String, title: String, subtitle: String = "", color: Color) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        ActionTileView(icon: icon, title: title, subtitle: subtitle, color: color)
    }
}

// MARK: - Backward Compat: FloatingCard3D

struct FloatingCard3D: ViewModifier {
    let isActive: Bool
    @State private var floatOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: isActive ? floatOffset : 0)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    floatOffset = -4
                }
            }
    }
}

extension View {
    func floating3D(_ active: Bool = true) -> some View {
        modifier(FloatingCard3D(isActive: active))
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
                pattern: theme.backgroundPattern,
                color: theme.palette.primary,
                scaleFactor: 0.3,
                opacity: theme.layers.patternOpacity
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
