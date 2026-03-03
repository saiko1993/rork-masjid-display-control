import SwiftUI

struct DisplayRendererView: View {
    let store: AppStore
    let theme: ThemeDefinition
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let now: Date

    @State private var adhanPulse: Bool = false
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var neonFlickerOn: Bool = true
    @State private var neonFlickerCount: Int = 0

    private var scaleFactor: CGFloat {
        let raw = min(screenWidth / 1920, screenHeight / 1080)
        return min(max(raw, theme.tokens.minFontScale), theme.tokens.maxFontScale)
    }

    private var isCompact: Bool {
        screenWidth < 1000 || store.display.layout == .compactV1
    }

    private var effectiveSchedule: [PrayerTime] {
        if store.prayerSchedule.isEmpty {
            return ScheduleSimulator.generateSchedule(
                for: store.location,
                date: now,
                iqamaConfig: store.iqama,
                jumuahConfig: store.jumuah
            )
        }
        return store.prayerSchedule
    }

    var body: some View {
        let state = PrayerStateMachine.evaluate(
            now: now,
            schedule: effectiveSchedule,
            adhanActiveSeconds: store.advanced.adhanActiveSeconds,
            iqamaConfig: store.iqama,
            prayerInProgressMinutes: store.advanced.prayerInProgressMinutes
        )

        let shouldPauseTicker = store.display.pauseTickerDuringAdhan && (state.phase == .adhanActive || state.phase == .iqamaCountdown || state.phase == .prayerInProgress)

        ZStack {
            backgroundLayer
            patternLayer
            vignetteLayer

            if theme.layers.hasShimmer {
                shimmerLayer
            }

            adhanOverlay(phase: state.phase)

            if isCompact {
                compactLayout(state: state, pauseTicker: shouldPauseTicker)
            } else {
                wideLayout(state: state, pauseTicker: shouldPauseTicker)
            }

            if store.demoMode {
                VStack {
                    HStack {
                        Spacer()
                        Text("DEMO / وضع تجريبي")
                            .font(.system(size: max(8, 10 * scaleFactor), weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 8 * scaleFactor)
                            .padding(.vertical, 4 * scaleFactor)
                            .background(.red.opacity(0.6))
                            .clipShape(.rect(cornerRadius: 4 * scaleFactor))
                            .padding(theme.tokens.safeMargins * scaleFactor)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: screenWidth, height: screenHeight)
        .clipped()
        .onChange(of: state.phase) { oldVal, newVal in
            if newVal == .adhanActive {
                startAdhanAnimation()
            } else {
                stopAdhanAnimation()
            }
        }
        .onAppear {
            if state.phase == .adhanActive {
                startAdhanAnimation()
            }
            if theme.layers.hasShimmer {
                startShimmer()
            }
        }
    }

    // MARK: - Layer 1: Base Gradient

    @ViewBuilder
    private var backgroundLayer: some View {
        let stops = theme.layers.gradientStops
        if stops.count >= 2 {
            LinearGradient(
                stops: stops.map { Gradient.Stop(color: $0.color, location: $0.location) },
                startPoint: gradientStart(angle: theme.layers.gradientAngle),
                endPoint: gradientEnd(angle: theme.layers.gradientAngle)
            )
        } else {
            theme.palette.background
        }
    }

    // MARK: - Layer 2: Pattern

    private var patternLayer: some View {
        IslamicPatternView(
            pattern: theme.backgroundPattern,
            color: theme.palette.primary,
            scaleFactor: scaleFactor,
            opacity: theme.layers.patternOpacity
        )
    }

    // MARK: - Layer 3: Vignette

    @ViewBuilder
    private var vignetteLayer: some View {
        switch theme.layers.vignetteStyle {
        case .radialDark:
            RadialGradient(
                colors: [.clear, theme.palette.background.opacity(theme.layers.vignetteIntensity)],
                center: .center,
                startRadius: screenWidth * 0.25,
                endRadius: screenWidth * 0.7
            )
        case .radialLight:
            RadialGradient(
                colors: [.white.opacity(theme.layers.vignetteIntensity * 0.5), .clear],
                center: .center,
                startRadius: 0,
                endRadius: screenWidth * 0.5
            )
        case .topFade:
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.palette.background.opacity(theme.layers.vignetteIntensity), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: screenHeight * 0.25)
                Spacer()
            }
        case .bottomFade:
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, theme.palette.background.opacity(theme.layers.vignetteIntensity)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: screenHeight * 0.35)
            }
        case .edgeBurn:
            ZStack {
                RadialGradient(
                    colors: [.clear, .black.opacity(theme.layers.vignetteIntensity * 0.6)],
                    center: .center,
                    startRadius: screenWidth * 0.3,
                    endRadius: screenWidth * 0.8
                )
                LinearGradient(
                    colors: [.black.opacity(theme.layers.vignetteIntensity * 0.3), .clear, .clear, .black.opacity(theme.layers.vignetteIntensity * 0.3)],
                    startPoint: .leading, endPoint: .trailing
                )
            }
        case .none:
            Color.clear.frame(width: 0, height: 0)
        }
    }

    // MARK: - Layer 3.5: Shimmer

    private var shimmerLayer: some View {
        GeometryReader { _ in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: max(0, shimmerPhase - 0.15)),
                    .init(color: theme.layers.shimmerColor, location: shimmerPhase),
                    .init(color: .clear, location: min(1, shimmerPhase + 0.15)),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Layer 4: Adhan Overlay

    @ViewBuilder
    private func adhanOverlay(phase: PrayerPhase) -> some View {
        if phase == .adhanActive {
            switch theme.layers.glowStyle {
            case .softBreath:
                theme.palette.adhanGlow
                    .opacity(adhanPulse ? 0.28 : 0.18)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: adhanPulse)

            case .pulse:
                theme.palette.adhanGlow
                    .opacity(adhanPulse ? 0.35 : 0.15)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: adhanPulse)

            case .radialBurst:
                RadialGradient(
                    colors: [
                        theme.palette.adhanGlow.opacity(adhanPulse ? 0.5 : 0.2),
                        theme.palette.adhanGlow.opacity(adhanPulse ? 0.15 : 0.05),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: screenWidth * (adhanPulse ? 0.55 : 0.4)
                )
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: adhanPulse)

            case .borderGlow:
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(
                        theme.palette.accent.opacity(adhanPulse ? 0.5 : 0.15),
                        lineWidth: (adhanPulse ? 8 : 4) * scaleFactor
                    )
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: adhanPulse)

            case .shimmerWave:
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: max(0, shimmerPhase - 0.2)),
                        .init(color: theme.palette.adhanGlow.opacity(0.4), location: shimmerPhase),
                        .init(color: .clear, location: min(1, shimmerPhase + 0.2)),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

            case .neonFlicker:
                theme.palette.adhanGlow
                    .opacity(neonFlickerOn ? 0.3 : 0.0)
            }
        }
    }

    // MARK: - Themed Card Wrapper

    @ViewBuilder
    private func themedCard<Content: View>(isHighlighted: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        let cfg = theme.layers

        Group {
            content()
        }
        .padding(theme.tokens.cardPadding * scaleFactor)
        .background {
            switch cfg.cardElevation {
            case .glassmorphic:
                ZStack {
                    theme.palette.surface.opacity(0.35)
                    if let glow = cfg.innerGlowColor {
                        LinearGradient(colors: [glow, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            case .neumorphic:
                theme.palette.surface
            case .inset:
                ZStack {
                    theme.palette.surface.opacity(0.6)
                    LinearGradient(colors: [.black.opacity(0.1), .clear, .white.opacity(0.02)], startPoint: .top, endPoint: .bottom)
                }
            case .floating:
                ZStack {
                    theme.palette.surface.opacity(0.55)
                    if let glow = cfg.innerGlowColor {
                        glow
                    }
                }
            case .raised:
                ZStack {
                    theme.palette.surface.opacity(0.5)
                    if let highlight = cfg.highlightShadowColor {
                        LinearGradient(colors: [highlight.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            case .flat:
                theme.palette.surface.opacity(0.3)
            }
        }
        .clipShape(.rect(cornerRadius: theme.tokens.cornerRadius * scaleFactor))
        .overlay(
            Group {
                if let borderColor = cfg.cardBorderColor, cfg.cardBorderOpacity > 0 {
                    RoundedRectangle(cornerRadius: theme.tokens.cornerRadius * scaleFactor)
                        .strokeBorder(borderColor.opacity(cfg.cardBorderOpacity), lineWidth: theme.tokens.borderWidth * scaleFactor)
                }
            }
        )
        .modifier(CardShadowModifier(
            elevation: cfg.cardElevation,
            shadowColor: cfg.cardShadowColor,
            lightColor: cfg.neumorphicLightColor,
            radius: theme.tokens.shadowRadius * scaleFactor,
            scaleFactor: scaleFactor
        ))
    }

    // MARK: - Wide Layout

    private func wideLayout(state: PrayerStateInfo, pauseTicker: Bool) -> some View {
        HStack(spacing: 16 * scaleFactor) {
            VStack(spacing: 12 * scaleFactor) {
                Spacer()
                BigClockView(time: now, theme: theme, scaleFactor: scaleFactor)
                DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)
                Spacer()
                themedCard {
                    CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                if store.display.showDhikrTicker {
                    DhikrTickerView(
                        theme: theme,
                        scaleFactor: scaleFactor,
                        direction: store.display.tickerDirection,
                        isPaused: pauseTicker
                    )
                    .padding(.bottom, 8 * scaleFactor)
                }

                themedCard {
                    PrayerTableView(
                        schedule: effectiveSchedule,
                        stateInfo: state,
                        theme: theme,
                        language: store.display.language,
                        scaleFactor: scaleFactor,
                        isCompact: false
                    )
                }

                Spacer()

                HStack {
                    Text(store.location.cityName)
                        .font(.system(size: 11 * scaleFactor, weight: .medium))
                        .foregroundStyle(theme.palette.textSecondary)

                    if store.advanced.scheduleMode == "simulated" {
                        Text("·")
                            .foregroundStyle(theme.palette.textSecondary)
                        Text("Simulated")
                            .font(.system(size: 9 * scaleFactor, weight: .regular))
                            .foregroundStyle(theme.palette.textSecondary.opacity(0.6))
                    }
                }
                .padding(.bottom, 8 * scaleFactor)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(max(14, theme.tokens.safeMargins * scaleFactor))
    }

    // MARK: - Compact Layout

    private func compactLayout(state: PrayerStateInfo, pauseTicker: Bool) -> some View {
        VStack(spacing: 8 * scaleFactor) {
            BigClockView(time: now, theme: theme, scaleFactor: scaleFactor)

            DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)

            if store.display.showDhikrTicker {
                DhikrTickerView(
                    theme: theme,
                    scaleFactor: scaleFactor,
                    direction: store.display.tickerDirection,
                    isPaused: pauseTicker
                )
            }

            themedCard {
                CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor)
            }

            themedCard {
                PrayerTableView(
                    schedule: effectiveSchedule,
                    stateInfo: state,
                    theme: theme,
                    language: store.display.language,
                    scaleFactor: scaleFactor,
                    isCompact: true
                )
            }

            Spacer(minLength: 0)
        }
        .padding(max(10, 12 * scaleFactor))
    }

    // MARK: - Animation Control

    private func startAdhanAnimation() {
        adhanPulse = true

        if theme.layers.glowStyle == .neonFlicker {
            neonFlickerCount = 0
            runNeonFlicker()
        }

        if theme.layers.glowStyle == .shimmerWave {
            startShimmer()
        }
    }

    private func stopAdhanAnimation() {
        adhanPulse = false
        neonFlickerOn = true
        neonFlickerCount = 0
    }

    private func runNeonFlicker() {
        guard neonFlickerCount < 6 else {
            neonFlickerOn = true
            return
        }
        neonFlickerCount += 1
        neonFlickerOn.toggle()

        Task {
            try? await Task.sleep(for: .milliseconds(neonFlickerOn ? 300 : 120))
            runNeonFlicker()
        }
    }

    private func startShimmer() {
        shimmerPhase = -0.3
        withAnimation(.linear(duration: theme.layers.shimmerSpeed).repeatForever(autoreverses: false)) {
            shimmerPhase = 1.3
        }
    }

    // MARK: - Helpers

    private func gradientStart(angle: Double) -> UnitPoint {
        let rad = angle * .pi / 180
        return UnitPoint(x: 0.5 - cos(rad) * 0.5, y: 0.5 - sin(rad) * 0.5)
    }

    private func gradientEnd(angle: Double) -> UnitPoint {
        let rad = angle * .pi / 180
        return UnitPoint(x: 0.5 + cos(rad) * 0.5, y: 0.5 + sin(rad) * 0.5)
    }
}

// MARK: - Card Shadow Modifier

struct CardShadowModifier: ViewModifier {
    let elevation: ElevationStyle
    let shadowColor: Color
    let lightColor: Color?
    let radius: CGFloat
    let scaleFactor: CGFloat

    func body(content: Content) -> some View {
        switch elevation {
        case .neumorphic:
            content
                .shadow(color: shadowColor, radius: radius, x: 4 * scaleFactor, y: 4 * scaleFactor)
                .shadow(color: (lightColor ?? .white).opacity(0.05), radius: radius * 0.6, x: -3 * scaleFactor, y: -3 * scaleFactor)
        case .raised:
            content
                .shadow(color: shadowColor, radius: radius, y: 4 * scaleFactor)
                .shadow(color: .white.opacity(0.04), radius: radius * 0.3, y: -2 * scaleFactor)
        case .floating:
            content
                .shadow(color: shadowColor, radius: radius * 1.2, y: 6 * scaleFactor)
        case .inset:
            content
                .shadow(color: shadowColor.opacity(0.3), radius: radius * 0.4, y: 2 * scaleFactor)
        case .glassmorphic:
            content
                .shadow(color: shadowColor, radius: radius * 1.1, y: 4 * scaleFactor)
        case .flat:
            content
        }
    }
}
