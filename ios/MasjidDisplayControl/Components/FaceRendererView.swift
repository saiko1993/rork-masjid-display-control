import SwiftUI

struct FaceRendererView: View {
    let store: AppStore
    let faceConfig: FaceConfiguration
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let now: Date

    @State private var adhanPulse: Bool = false
    @State private var shimmerPhase: CGFloat = -1.0

    private var theme: ThemeDefinition {
        let base = ThemeDefinition.theme(for: faceConfig.themeId)
        let override = store.themeCustomizations.override(for: faceConfig.themeId)
        return override.hasOverrides ? base.applying(override: override) : base
    }

    private var breakpoint: ScreenBreakpoint {
        ScreenBreakpoint.from(width: screenWidth, height: screenHeight)
    }

    private var scaleFactor: CGFloat {
        let raw = min(screenWidth / 1920, screenHeight / 1080)
        return min(max(raw, theme.tokens.minFontScale), theme.tokens.maxFontScale)
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

    private var state: PrayerStateInfo {
        PrayerStateMachine.evaluate(
            now: now,
            schedule: effectiveSchedule,
            adhanActiveSeconds: store.advanced.adhanActiveSeconds,
            iqamaConfig: store.iqama,
            prayerInProgressMinutes: store.advanced.prayerInProgressMinutes
        )
    }

    private var shouldPauseTicker: Bool {
        store.display.pauseTickerDuringAdhan && (state.phase == .adhanActive || state.phase == .iqamaCountdown || state.phase == .prayerInProgress)
    }

    private func has(_ c: FaceComponentId) -> Bool {
        faceConfig.hasComponent(c)
    }

    var body: some View {
        ZStack {
            backgroundLayers
            adhanOverlay
            faceLayout
            demoWatermark
        }
        .frame(width: screenWidth, height: screenHeight)
        .clipped()
        .onChange(of: state.phase) { _, newVal in
            adhanPulse = newVal == .adhanActive
        }
        .onAppear {
            adhanPulse = state.phase == .adhanActive
            if theme.layers.hasShimmer {
                shimmerPhase = -0.3
                withAnimation(.linear(duration: theme.layers.shimmerSpeed).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.3
                }
            }
        }
    }

    // MARK: - Background Layers

    @ViewBuilder
    private var backgroundLayers: some View {
        let stops = theme.layers.gradientStops
        if stops.count >= 2 {
            LinearGradient(
                stops: stops.map { Gradient.Stop(color: $0.color, location: $0.location) },
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            theme.palette.background
        }

        IslamicPatternView(
            pattern: theme.backgroundPattern,
            color: theme.palette.primary,
            scaleFactor: scaleFactor,
            opacity: theme.layers.patternOpacity
        )

        vignetteLayer

        if theme.layers.hasShimmer {
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
    }

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
        case .edgeBurn:
            RadialGradient(
                colors: [.clear, .black.opacity(theme.layers.vignetteIntensity * 0.6)],
                center: .center,
                startRadius: screenWidth * 0.3,
                endRadius: screenWidth * 0.8
            )
        case .bottomFade:
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [.clear, theme.palette.background.opacity(theme.layers.vignetteIntensity)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: screenHeight * 0.35)
            }
        case .topFade:
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [theme.palette.background.opacity(theme.layers.vignetteIntensity), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: screenHeight * 0.25)
                Spacer()
            }
        case .none:
            Color.clear.frame(width: 0, height: 0)
        }
    }

    @ViewBuilder
    private var adhanOverlay: some View {
        if state.phase == .adhanActive {
            theme.palette.adhanGlow
                .opacity(adhanPulse ? 0.3 : 0.12)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: adhanPulse)
        }
    }

    @ViewBuilder
    private var demoWatermark: some View {
        if store.demoMode {
            VStack {
                HStack {
                    Spacer()
                    Text("DEMO")
                        .font(.system(size: max(8, 10 * scaleFactor), weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 8 * scaleFactor)
                        .padding(.vertical, 4 * scaleFactor)
                        .background(.red.opacity(0.6))
                        .clipShape(.rect(cornerRadius: 4 * scaleFactor))
                        .padding(breakpoint.safeMargin * scaleFactor)
                }
                Spacer()
            }
        }
    }

    // MARK: - Themed Card

    @ViewBuilder
    private func themedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let cfg = theme.layers
        content()
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
                        LinearGradient(colors: [.black.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)
                    }
                case .floating:
                    ZStack {
                        theme.palette.surface.opacity(0.55)
                        if let glow = cfg.innerGlowColor { glow }
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
            .shadow(color: cfg.cardShadowColor, radius: theme.tokens.shadowRadius * scaleFactor, y: 4 * scaleFactor)
    }

    // MARK: - Phase Badge

    @ViewBuilder
    private var phaseBadgeComponent: some View {
        if has(.phaseBadge) {
            let label: String = {
                switch state.phase {
                case .normal: return ""
                case .adhanActive: return store.display.language == .ar ? "أذان" : "ADHAN"
                case .iqamaCountdown: return store.display.language == .ar ? "إقامة" : "IQAMA"
                case .prayerInProgress: return store.display.language == .ar ? "صلاة" : "PRAYER"
                }
            }()
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 12 * scaleFactor, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10 * scaleFactor)
                    .padding(.vertical, 4 * scaleFactor)
                    .background(
                        state.phase == .adhanActive ? theme.palette.accent :
                        state.phase == .iqamaCountdown ? Color.orange :
                        Color.green
                    )
                    .clipShape(.capsule)
            }
        }
    }

    // MARK: - Countdown Ring

    @ViewBuilder
    private var countdownRingComponent: some View {
        if has(.countdownRing), state.phase != .prayerInProgress {
            let total: Int = state.phase == .normal ? 3600 : (state.phase == .adhanActive ? store.advanced.adhanActiveSeconds : 1200)
            let current: Int = {
                switch state.phase {
                case .normal: return state.countdownSeconds
                case .adhanActive: return state.adhanRemainingSeconds
                case .iqamaCountdown: return state.iqamaCountdownSeconds
                case .prayerInProgress: return 0
                }
            }()
            let progress = total > 0 ? 1.0 - Double(current) / Double(total) : 0

            ZStack {
                Circle()
                    .stroke(theme.palette.surface.opacity(0.3), lineWidth: 6 * scaleFactor)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.palette.accent, style: StrokeStyle(lineWidth: 6 * scaleFactor, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: theme.palette.accent.opacity(0.4), radius: 8 * scaleFactor)

                VStack(spacing: 2 * scaleFactor) {
                    Text(formatCountdown(current))
                        .font(.system(size: 18 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                        .foregroundStyle(theme.palette.textPrimary)
                        .monospacedDigit()
                }
            }
            .frame(width: 100 * scaleFactor, height: 100 * scaleFactor)
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerComponent: some View {
        if has(.footer) {
            HStack {
                Text(store.location.cityName)
                    .font(.system(size: 11 * scaleFactor, weight: .medium))
                    .foregroundStyle(theme.palette.textSecondary)
                if store.advanced.scheduleMode == "simulated" {
                    Text("·")
                        .foregroundStyle(theme.palette.textSecondary)
                    Text("Simulated")
                        .font(.system(size: 9 * scaleFactor))
                        .foregroundStyle(theme.palette.textSecondary.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Next Prayer Card

    @ViewBuilder
    private var nextPrayerCardComponent: some View {
        if has(.nextPrayerCard), let next = state.nextPrayer {
            themedCard {
                VStack(spacing: 6 * scaleFactor) {
                    HStack(spacing: 6 * scaleFactor) {
                        Image(systemName: next.iconName)
                            .font(.system(size: 16 * scaleFactor))
                            .foregroundStyle(theme.palette.accent)
                        Text(store.display.language == .ar ? next.displayNameAr : next.displayName)
                            .font(.system(size: 16 * scaleFactor, weight: .semibold))
                            .foregroundStyle(theme.palette.textPrimary)
                    }
                    Text(formatCountdown(state.countdownSeconds))
                        .font(.system(size: 28 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                        .foregroundStyle(theme.palette.primary)
                        .monospacedDigit()
                        .shadow(color: theme.palette.primary.opacity(0.3), radius: theme.layers.countdownGlowRadius * scaleFactor * 0.4)
                }
            }
        }
    }

    // MARK: - Face Layouts

    @ViewBuilder
    private var faceLayout: some View {
        switch faceConfig.faceId {
        case .classicSplit: classicSplitLayout
        case .archFrame: archFrameLayout
        case .minimalNoor: minimalNoorLayout
        case .ledBoard: ledBoardLayout
        case .smartGlass: smartGlassLayout
        case .ottomanGold: ottomanGoldLayout
        }
    }

    // MARK: 1) Classic Split

    private var classicSplitLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return HStack(spacing: 16 * scaleFactor) {
            VStack(spacing: 12 * scaleFactor) {
                Spacer()
                if has(.clock) {
                    BigClockView(time: now, theme: theme, scaleFactor: scaleFactor, timeFormat: store.timeFormat)
                }
                if has(.dateBlock) {
                    DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)
                }
                Spacer()
                if has(.countdownText) || has(.countdownRing) {
                    themedCard {
                        HStack(spacing: 16 * scaleFactor) {
                            if has(.countdownRing) { countdownRingComponent }
                            if has(.countdownText) {
                                CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor)
                            }
                        }
                    }
                }
                phaseBadgeComponent
                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                if has(.ticker) {
                    DhikrTickerView(
                        theme: theme,
                        scaleFactor: scaleFactor,
                        direction: store.display.tickerDirection,
                        isPaused: shouldPauseTicker
                    )
                    .padding(.bottom, 8 * scaleFactor)
                }
                if has(.prayerTable) {
                    themedCard {
                        PrayerTableView(
                            schedule: effectiveSchedule,
                            stateInfo: state,
                            theme: theme,
                            language: store.display.language,
                            scaleFactor: scaleFactor,
                            isCompact: false,
                            timeFormat: store.timeFormat
                        )
                    }
                }
                Spacer()
                footerComponent
                    .padding(.bottom, 8 * scaleFactor)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(max(14, margin))
    }

    // MARK: 2) Arch Frame

    private var archFrameLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return VStack(spacing: 10 * scaleFactor) {
            archDecoration
                .frame(height: 40 * scaleFactor)

            if has(.clock) {
                BigClockView(time: now, theme: theme, scaleFactor: scaleFactor * 1.1, timeFormat: store.timeFormat)
            }

            HStack(spacing: 12 * scaleFactor) {
                if has(.dateBlock) {
                    DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)
                }
                phaseBadgeComponent
            }

            if has(.countdownText) {
                themedCard {
                    CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor)
                }
            }

            if has(.prayerTable) {
                themedCard {
                    PrayerTableView(
                        schedule: effectiveSchedule,
                        stateInfo: state,
                        theme: theme,
                        language: store.display.language,
                        scaleFactor: scaleFactor,
                        isCompact: breakpoint == .tiny || breakpoint == .small,
                        timeFormat: store.timeFormat
                    )
                }
            }

            Spacer(minLength: 0)

            if has(.ticker) {
                DhikrTickerView(
                    theme: theme,
                    scaleFactor: scaleFactor,
                    direction: store.display.tickerDirection,
                    isPaused: shouldPauseTicker
                )
            }

            footerComponent
        }
        .padding(max(14, margin))
    }

    private var archDecoration: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: 0, y: h))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: h),
                    control: CGPoint(x: w / 2, y: -h * 0.6)
                )
            }
            .stroke(theme.palette.accent.opacity(0.3), lineWidth: 2 * scaleFactor)
        }
    }

    // MARK: 3) Minimal Noor

    private var minimalNoorLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return VStack(spacing: 0) {
            Spacer()

            if has(.clock) {
                BigClockView(time: now, theme: theme, scaleFactor: scaleFactor * 1.4, timeFormat: store.timeFormat)
            }

            if has(.dateBlock) {
                DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)
                    .padding(.top, 8 * scaleFactor)
            }

            Spacer()

            if has(.countdownText), state.phase != .prayerInProgress {
                HStack(spacing: 8 * scaleFactor) {
                    if let next = state.nextPrayer {
                        Text(store.display.language == .ar ? next.displayNameAr : next.displayName)
                            .font(.system(size: 16 * scaleFactor, weight: .semibold))
                            .foregroundStyle(theme.palette.accent)
                    }
                    Text(formatCountdown(state.countdownSeconds))
                        .font(.system(size: 20 * scaleFactor, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                        .foregroundStyle(theme.palette.primary)
                        .monospacedDigit()
                }
                .padding(.bottom, 12 * scaleFactor)
            }

            phaseBadgeComponent

            if has(.prayerTable) {
                minimalPrayerRow
                    .padding(.vertical, 12 * scaleFactor)
            }

            if has(.ticker) {
                DhikrTickerView(
                    theme: theme,
                    scaleFactor: scaleFactor,
                    direction: store.display.tickerDirection,
                    isPaused: shouldPauseTicker
                )
            }

            footerComponent
                .padding(.top, 6 * scaleFactor)
        }
        .padding(max(14, margin))
    }

    private var minimalPrayerRow: some View {
        HStack(spacing: 0) {
            ForEach(effectiveSchedule) { pt in
                let isNext = state.nextPrayer == pt.prayer && state.phase == .normal
                VStack(spacing: 4 * scaleFactor) {
                    Text(store.display.language == .ar ? pt.prayer.displayNameAr : pt.prayer.displayName)
                        .font(.system(size: 11 * scaleFactor, weight: isNext ? .bold : .medium))
                        .foregroundStyle(isNext ? theme.palette.accent : theme.palette.textSecondary)
                    Text(timeString(pt.time))
                        .font(.system(size: 14 * scaleFactor, weight: .semibold, design: theme.typography.timeFontDesign))
                        .foregroundStyle(isNext ? theme.palette.primary : theme.palette.textPrimary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8 * scaleFactor)
                .background(isNext ? theme.palette.primary.opacity(0.12) : Color.clear)
                .clipShape(.rect(cornerRadius: 8 * scaleFactor))
            }
        }
        .padding(.horizontal, 8 * scaleFactor)
        .padding(.vertical, 6 * scaleFactor)
        .background(theme.palette.surface.opacity(0.3))
        .clipShape(.rect(cornerRadius: theme.tokens.cornerRadius * scaleFactor))
    }

    // MARK: 4) LED Board

    private var ledBoardLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return VStack(spacing: 4 * scaleFactor) {
            HStack {
                if has(.clock) {
                    BigClockView(time: now, theme: theme, scaleFactor: scaleFactor * 0.9, timeFormat: store.timeFormat)
                }
                Spacer()
                if has(.dateBlock) {
                    DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor * 0.8)
                }
                phaseBadgeComponent
            }
            .padding(.horizontal, 8 * scaleFactor)

            Rectangle()
                .fill(theme.palette.primary.opacity(0.2))
                .frame(height: 1 * scaleFactor)

            if has(.countdownText) {
                HStack {
                    CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor * 0.85)
                }
                .padding(.vertical, 4 * scaleFactor)
            }

            Rectangle()
                .fill(theme.palette.primary.opacity(0.2))
                .frame(height: 1 * scaleFactor)

            if has(.prayerTable) {
                ledPrayerRows
            }

            Spacer(minLength: 0)

            if has(.ticker) {
                DhikrTickerView(
                    theme: theme,
                    scaleFactor: scaleFactor,
                    direction: store.display.tickerDirection,
                    isPaused: shouldPauseTicker
                )
            }

            footerComponent
        }
        .padding(max(8, margin))
    }

    private var ledPrayerRows: some View {
        VStack(spacing: 2 * scaleFactor) {
            ForEach(effectiveSchedule) { pt in
                let isNext = state.nextPrayer == pt.prayer && state.phase == .normal
                let isActive = state.currentPrayer == pt.prayer && state.phase != .normal

                HStack {
                    Image(systemName: pt.prayer.iconName)
                        .font(.system(size: 12 * scaleFactor))
                        .foregroundStyle(isActive ? theme.palette.accent : theme.palette.primary)
                        .frame(width: 20 * scaleFactor)

                    Text(store.display.language == .ar ? pt.prayer.displayNameAr : pt.prayer.displayName)
                        .font(.system(size: 14 * scaleFactor, weight: isNext ? .bold : .medium))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(timeString(pt.time))
                        .font(.system(size: 14 * scaleFactor, weight: .semibold, design: theme.typography.timeFontDesign))
                        .monospacedDigit()
                        .frame(width: 60 * scaleFactor, alignment: .trailing)

                    if let iqama = pt.iqamaTime {
                        Text(timeString(iqama))
                            .font(.system(size: 12 * scaleFactor, weight: .medium, design: theme.typography.timeFontDesign))
                            .monospacedDigit()
                            .foregroundStyle(theme.palette.textSecondary)
                            .frame(width: 60 * scaleFactor, alignment: .trailing)
                    }
                }
                .foregroundStyle(isActive ? theme.palette.accent : (isNext ? theme.palette.primary : theme.palette.textPrimary))
                .padding(.vertical, 4 * scaleFactor)
                .padding(.horizontal, 8 * scaleFactor)
                .background(isNext ? theme.palette.primary.opacity(0.1) : (isActive ? theme.palette.accent.opacity(0.1) : Color.clear))
            }
        }
    }

    // MARK: 5) Smart Glass

    private var smartGlassLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return HStack(spacing: 14 * scaleFactor) {
            VStack(spacing: 12 * scaleFactor) {
                themedCard {
                    VStack(spacing: 8 * scaleFactor) {
                        if has(.clock) {
                            BigClockView(time: now, theme: theme, scaleFactor: scaleFactor * 0.85, timeFormat: store.timeFormat)
                        }
                        if has(.dateBlock) {
                            DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor * 0.85)
                        }
                    }
                }

                if has(.nextPrayerCard) || has(.countdownRing) {
                    themedCard {
                        HStack(spacing: 12 * scaleFactor) {
                            countdownRingComponent
                            if has(.countdownText) {
                                CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor * 0.85)
                            }
                        }
                    }
                } else if has(.countdownText) {
                    themedCard {
                        CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor * 0.85)
                    }
                }

                phaseBadgeComponent
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                if has(.prayerTable) {
                    themedCard {
                        PrayerTableView(
                            schedule: effectiveSchedule,
                            stateInfo: state,
                            theme: theme,
                            language: store.display.language,
                            scaleFactor: scaleFactor,
                            isCompact: breakpoint == .tiny,
                            timeFormat: store.timeFormat
                        )
                    }
                }

                Spacer(minLength: 0)

                if has(.ticker) {
                    DhikrTickerView(
                        theme: theme,
                        scaleFactor: scaleFactor,
                        direction: store.display.tickerDirection,
                        isPaused: shouldPauseTicker
                    )
                    .padding(.top, 8 * scaleFactor)
                }

                footerComponent
                    .padding(.top, 6 * scaleFactor)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(max(14, margin))
    }

    // MARK: 6) Ottoman Gold

    private var ottomanGoldLayout: some View {
        let margin = breakpoint.safeMargin * scaleFactor
        return VStack(spacing: 10 * scaleFactor) {
            ottomanOrnament

            if has(.clock) {
                BigClockView(time: now, theme: theme, scaleFactor: scaleFactor * 1.15, timeFormat: store.timeFormat)
                    .padding(.vertical, 4 * scaleFactor)
            }

            if has(.dateBlock) {
                DateBlockView(date: now, config: store.dateDisplay, theme: theme, scaleFactor: scaleFactor)
            }

            ottomanDivider

            HStack(spacing: 16 * scaleFactor) {
                if has(.countdownText) {
                    themedCard {
                        CountdownView(stateInfo: state, theme: theme, language: store.display.language, scaleFactor: scaleFactor * 0.9)
                    }
                }
                phaseBadgeComponent
            }

            if has(.prayerTable) {
                themedCard {
                    PrayerTableView(
                        schedule: effectiveSchedule,
                        stateInfo: state,
                        theme: theme,
                        language: store.display.language,
                        scaleFactor: scaleFactor,
                        isCompact: breakpoint == .tiny || breakpoint == .small,
                        timeFormat: store.timeFormat
                    )
                }
            }

            Spacer(minLength: 0)

            if has(.ticker) {
                DhikrTickerView(
                    theme: theme,
                    scaleFactor: scaleFactor,
                    direction: store.display.tickerDirection,
                    isPaused: shouldPauseTicker
                )
            }

            ottomanDivider
            footerComponent
        }
        .padding(max(14, margin))
    }

    private var ottomanOrnament: some View {
        HStack(spacing: 8 * scaleFactor) {
            ornamentalLine
            Image(systemName: "star.fill")
                .font(.system(size: 10 * scaleFactor))
                .foregroundStyle(theme.palette.accent)
            Image(systemName: "seal.fill")
                .font(.system(size: 16 * scaleFactor))
                .foregroundStyle(theme.palette.primary.opacity(0.6))
            Image(systemName: "star.fill")
                .font(.system(size: 10 * scaleFactor))
                .foregroundStyle(theme.palette.accent)
            ornamentalLine
        }
    }

    private var ornamentalLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, theme.palette.accent.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1 * scaleFactor)
            .frame(maxWidth: .infinity)
    }

    private var ottomanDivider: some View {
        HStack(spacing: 6 * scaleFactor) {
            Rectangle()
                .fill(theme.palette.accent.opacity(0.2))
                .frame(height: 0.5 * scaleFactor)
                .frame(maxWidth: .infinity)
            Circle()
                .fill(theme.palette.accent.opacity(0.3))
                .frame(width: 4 * scaleFactor, height: 4 * scaleFactor)
            Rectangle()
                .fill(theme.palette.accent.opacity(0.2))
                .frame(height: 0.5 * scaleFactor)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func formatCountdown(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private static let formatter12: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    private static let formatter24: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private func timeString(_ date: Date) -> String {
        let f = store.timeFormat == .twelve ? Self.formatter12 : Self.formatter24
        return f.string(from: date)
    }
}
