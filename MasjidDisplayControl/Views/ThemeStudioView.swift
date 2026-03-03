import SwiftUI
import PhotosUI
import SwiftUIX
import SDWebImageSwiftUI

enum StudioTab: String, CaseIterable {
    case gradient = "Gradient"
    case background = "Background"
    case pattern = "Pattern"
    case colors = "Colors"
    case cards = "Cards"
    case ticker = "Ticker"
    case typography = "Typography"

    var icon: String {
        switch self {
        case .gradient: return "paintbrush.fill"
        case .background: return "photo.fill"
        case .pattern: return "square.grid.3x3.fill"
        case .colors: return "paintpalette.fill"
        case .cards: return "rectangle.on.rectangle.fill"
        case .ticker: return "text.line.first.and.arrowtriangle.forward"
        case .typography: return "textformat.size"
        }
    }
}

struct ThemeStudioView: View {
    @Bindable var store: AppStore
    let themeId: ThemeId
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    @State private var selectedTab: StudioTab = .gradient
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isUploading: Bool = false
    @State private var uploadSuccess: Bool = false
    @State private var pushInProgress: Bool = false
    @State private var pushSucceeded: Bool = false

    private var baseTheme: ThemeDefinition {
        ThemeDefinition.theme(for: themeId)
    }

    private var override: ThemeColorOverride {
        store.themeCustomizations.override(for: themeId)
    }

    private var effectiveTheme: ThemeDefinition {
        let o = override
        return o.hasOverrides ? baseTheme.applying(override: o) : baseTheme
    }

    var body: some View {
        VStack(spacing: 0) {
            livePreviewBanner
            tabSelector
            ScrollView {
                VStack(spacing: DS.Spacing.md) {
                    selectedTabContent
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .padding(.bottom, 120)
            }
        }
        .background(DepthStack(accentColor: effectiveTheme.palette.accent) { Color.clear })
        .navigationTitle("Theme Studio")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await handlePhotoSelection(newItem) }
        }
    }

    private var livePreviewBanner: some View {
        ThemePreviewThumbnail(theme: effectiveTheme)
            .frame(height: 120)
            .clipShape(.rect(cornerRadius: DS.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .strokeBorder(effectiveTheme.palette.accent.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: effectiveTheme.palette.accent.opacity(0.1), radius: 12, y: 4)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xs)
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(StudioTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(duration: 0.25)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.caption2)
                            Text(tab.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06))
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                        .clipShape(.capsule)
                    }
                }
            }
            .contentMargins(.horizontal, DS.Spacing.md)
        }
        .padding(.bottom, DS.Spacing.xs)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .gradient: gradientTab
        case .background: backgroundTab
        case .pattern: patternTab
        case .colors: colorsTab
        case .cards: cardsTab
        case .ticker: tickerTab
        case .typography: typographyTab
        }
    }

    // MARK: - Gradient Tab

    private var gradientTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Gradient Stops", icon: "square.stack.3d.up.fill", color: .blue)


            if baseTheme.layers.gradientStops.count > 0 {
                colorRow("Stop 1", hex: override.gradientStop0Hex, defaultColor: baseTheme.layers.gradientStops[0].color) { hex in
                    var o = override; o.gradientStop0Hex = hex; updateOverride(o)
                }
            }
            if baseTheme.layers.gradientStops.count > 1 {
                colorRow("Stop 2", hex: override.gradientStop1Hex, defaultColor: baseTheme.layers.gradientStops[1].color) { hex in
                    var o = override; o.gradientStop1Hex = hex; updateOverride(o)
                }
            }
            if baseTheme.layers.gradientStops.count > 2 {
                colorRow("Stop 3", hex: override.gradientStop2Hex, defaultColor: baseTheme.layers.gradientStops[2].color) { hex in
                    var o = override; o.gradientStop2Hex = hex; updateOverride(o)
                }
            }
            if baseTheme.layers.gradientStops.count > 3 {
                colorRow("Stop 4", hex: override.gradientStop3Hex, defaultColor: baseTheme.layers.gradientStops[3].color) { hex in
                    var o = override; o.gradientStop3Hex = hex; updateOverride(o)
                }
            }

            Divider().padding(.vertical, DS.Spacing.xs)

            sliderRow("Vignette Intensity", value: override.vignetteIntensity ?? Double(baseTheme.layers.vignetteIntensity), range: 0...1) { val in
                var o = override; o.vignetteIntensity = val; updateOverride(o)
            }

            layerInfoRow("Vignette Style", value: PayloadBuilder.vignetteString(baseTheme.layers.vignetteStyle))
            layerInfoRow("Gradient Angle", value: "\(Int(baseTheme.layers.gradientAngle))°")
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Background Tab

    private var backgroundTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Background Image", icon: "photo.fill", color: .green)

            if let url = override.backgroundImageUrl, !url.isEmpty {
                WebImage(url: URL(string: url)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            ProgressView()
                                .controlSize(.small)
                        }
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
                .frame(height: 120)
                .clipShape(.rect(cornerRadius: DS.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Image uploaded")
                        .font(.subheadline)
                    Spacer()
                    Button("Remove") {
                        var o = override
                        o.backgroundImageUrl = nil
                        o.backgroundImageFit = nil
                        o.backgroundImageBlur = nil
                        updateOverride(o)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                }

                HStack {
                    Text("Fit Mode")
                        .font(.subheadline)
                    Spacer()
                    Picker("Fit", selection: Binding(
                        get: { override.backgroundImageFit ?? "cover" },
                        set: { val in
                            var o = override; o.backgroundImageFit = val; updateOverride(o)
                        }
                    )) {
                        Text("Cover").tag("cover")
                        Text("Contain").tag("contain")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                sliderRow("Image Blur", value: override.backgroundImageBlur ?? 0, range: 0...20) { val in
                    var o = override; o.backgroundImageBlur = val; updateOverride(o)
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    if isUploading {
                        ProgressView().controlSize(.small)
                        Text("Uploading to Pi...")
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Upload Background Image")
                    }
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.sm)
                .background(Color.white.opacity(0.06))
                .clipShape(.rect(cornerRadius: DS.Radius.md))
            }
            .disabled(isUploading)

            if uploadSuccess {
                Label("Image uploaded successfully!", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            Text("Upload to Raspberry Pi server. Image will be resized to fit display resolution.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if isUploading {
                ProgressView(value: 0.5)
                    .tint(.green)
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Pattern Tab

    private var patternTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Pattern Overlay", icon: "square.grid.3x3.fill", color: .indigo)

            sliderRow("Pattern Opacity", value: override.patternOpacity ?? Double(baseTheme.layers.patternOpacity), range: 0...0.5) { val in
                var o = override; o.patternOpacity = val; updateOverride(o)
            }

            colorRow("Pattern Color", hex: override.patternColorHex, defaultColor: baseTheme.palette.primary) { hex in
                var o = override; o.patternColorHex = hex; updateOverride(o)
            }

            layerInfoRow("Pattern Type", value: PayloadBuilder.patternString(baseTheme.backgroundPattern))

            sliderRow("Glow Radius", value: override.countdownGlowRadius ?? Double(baseTheme.layers.countdownGlowRadius), range: 0...30) { val in
                var o = override; o.countdownGlowRadius = val; updateOverride(o)
            }

            HStack(spacing: DS.Spacing.xs) {
                layerChip("Shimmer", value: baseTheme.layers.hasShimmer ? "On" : "Off")
                layerChip("Glow", value: PayloadBuilder.glowString(baseTheme.layers.glowStyle))
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Colors Tab

    private var colorsTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Theme Colors", icon: "paintpalette.fill", color: .orange)

            colorRow("Background", hex: override.backgroundHex, defaultColor: baseTheme.palette.background) { hex in
                var o = override; o.backgroundHex = hex; updateOverride(o)
            }
            colorRow("Surface", hex: override.surfaceHex, defaultColor: baseTheme.palette.surface) { hex in
                var o = override; o.surfaceHex = hex; updateOverride(o)
            }
            colorRow("Primary", hex: override.primaryHex, defaultColor: baseTheme.palette.primary) { hex in
                var o = override; o.primaryHex = hex; updateOverride(o)
            }
            colorRow("Secondary", hex: override.secondaryHex, defaultColor: baseTheme.palette.secondary) { hex in
                var o = override; o.secondaryHex = hex; updateOverride(o)
            }
            colorRow("Text Primary", hex: override.textPrimaryHex, defaultColor: baseTheme.palette.textPrimary) { hex in
                var o = override; o.textPrimaryHex = hex; updateOverride(o)
            }
            colorRow("Text Secondary", hex: override.textSecondaryHex, defaultColor: baseTheme.palette.textSecondary) { hex in
                var o = override; o.textSecondaryHex = hex; updateOverride(o)
            }
            colorRow("Accent", hex: override.accentHex, defaultColor: baseTheme.palette.accent) { hex in
                var o = override; o.accentHex = hex; updateOverride(o)
            }
            colorRow("Adhan Glow", hex: override.adhanGlowHex, defaultColor: baseTheme.palette.adhanGlow) { hex in
                var o = override; o.adhanGlowHex = hex; updateOverride(o)
            }
            colorRow("Countdown", hex: override.countdownColorHex, defaultColor: baseTheme.palette.accent) { hex in
                var o = override; o.countdownColorHex = hex; updateOverride(o)
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Cards Tab

    private var cardsTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Card & Table Style", icon: "rectangle.on.rectangle.fill", color: .purple)

            colorRow("Card Border", hex: override.cardBorderColorHex, defaultColor: baseTheme.layers.cardBorderColor ?? .clear) { hex in
                var o = override; o.cardBorderColorHex = hex; updateOverride(o)
            }

            sliderRow("Border Opacity", value: override.cardBorderOpacity ?? Double(baseTheme.layers.cardBorderOpacity), range: 0...1) { val in
                var o = override; o.cardBorderOpacity = val; updateOverride(o)
            }

            sliderRow("Shadow Depth", value: override.cardShadowDepth ?? Double(baseTheme.tokens.shadowRadius), range: 0...30) { val in
                var o = override; o.cardShadowDepth = val; updateOverride(o)
            }

            Divider().padding(.vertical, DS.Spacing.xs)

            layerInfoRow("Elevation Style", value: PayloadBuilder.elevationString(baseTheme.layers.cardElevation))
            layerInfoRow("Row Separators", value: baseTheme.layers.tableRowSeparator ? "Yes" : "No")
            layerInfoRow("Row Inset", value: baseTheme.layers.tableRowInset ? "Yes" : "No")
            layerInfoRow("Corner Radius", value: "\(Int(baseTheme.tokens.cornerRadius))pt")
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Ticker Tab

    private var tickerTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Ticker Style", icon: "text.line.first.and.arrowtriangle.forward", color: .teal)

            colorRow("Ticker Background", hex: override.tickerBackgroundHex, defaultColor: baseTheme.layers.tickerBackground ?? .clear) { hex in
                var o = override; o.tickerBackgroundHex = hex; updateOverride(o)
            }

            colorRow("Ticker Text", hex: override.tickerTextHex, defaultColor: baseTheme.palette.textPrimary) { hex in
                var o = override; o.tickerTextHex = hex; updateOverride(o)
            }

            sliderRow("Ticker Opacity", value: override.tickerOpacity ?? 1.0, range: 0...1) { val in
                var o = override; o.tickerOpacity = val; updateOverride(o)
            }

            Divider().padding(.vertical, DS.Spacing.xs)

            HStack {
                Text("Direction")
                    .font(.subheadline)
                Spacer()
                Picker("Direction", selection: $store.display.tickerDirection) {
                    ForEach(TickerDirection.allCases, id: \.self) { d in
                        Text(d.displayName).tag(d)
                    }
                }
                .tint(.secondary)
            }

            Toggle("Pause During Adhan/Iqama", isOn: $store.ticker.pauseDuringAdhan)
                .font(.subheadline)

            Toggle("Show Ticker", isOn: $store.display.showDhikrTicker)
                .font(.subheadline)
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Typography Tab

    private var typographyTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Typography", icon: "textformat.size", color: .pink)

            layerInfoRow("Time Font", value: fontDesignLabel(baseTheme.typography.timeFontDesign))
            layerInfoRow("Arabic Font", value: fontDesignLabel(baseTheme.typography.arabicFontDesign))
            layerInfoRow("Latin Font", value: fontDesignLabel(baseTheme.typography.latinFontDesign))
            layerInfoRow("Time Weight", value: fontWeightLabel(baseTheme.typography.timeWeight))
            layerInfoRow("Heading Weight", value: fontWeightLabel(baseTheme.typography.headingWeight))

            Divider().padding(.vertical, DS.Spacing.xs)

            Toggle("Large Mode (Bigger Prayer Fonts)", isOn: $store.largeMode)
                .font(.subheadline)

            Text("Increases prayer name and time font sizes for visibility from distance.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, DS.Spacing.xs)

            HStack {
                Text("Time Format")
                    .font(.subheadline)
                Spacer()
                Picker("Format", selection: $store.timeFormat) {
                    ForEach(TimeFormat.allCases, id: \.self) { f in
                        Text(f.displayName).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            layerInfoRow("Min Font Scale", value: String(format: "%.2f", baseTheme.tokens.minFontScale))
            layerInfoRow("Max Font Scale", value: String(format: "%.2f", baseTheme.tokens.maxFontScale))
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: DS.Spacing.xs) {
            Divider()
            HStack(spacing: DS.Spacing.sm) {
                if override.hasOverrides {
                    Button {
                        withAnimation {
                            store.themeCustomizations.resetOverride(for: themeId)
                            store.save()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button {
                    pushTheme()
                } label: {
                    HStack(spacing: 8) {
                        if pushInProgress {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: pushSucceeded ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        }
                        Text(pushSucceeded ? "Pushed!" : "Save & Push to Display")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(pushSucceeded ? .green : .blue)
                .disabled(pushInProgress)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: pushSucceeded)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xs)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func colorRow(_ label: String, hex: String?, defaultColor: Color, onChange: @escaping (String?) -> Void) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()

            let currentColor: Color = Color(hexString: hex) ?? defaultColor

            ColorPicker("", selection: Binding<Color>(
                get: { currentColor },
                set: { newColor in onChange(newColor.toHexString) }
            ))
            .labelsHidden()

            if hex != nil {
                Button {
                    onChange(nil)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sliderRow(_ label: String, value: Double, range: ClosedRange<Double>, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: range)
            .tint(.blue)
        }
    }

    private func layerInfoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func layerChip(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .clipShape(.rect(cornerRadius: DS.Radius.sm))
    }

    private func fontDesignLabel(_ design: Font.Design) -> String {
        switch design {
        case .serif: return "Serif"
        case .monospaced: return "Monospaced"
        case .rounded: return "Rounded"
        default: return "Default (SF Pro)"
        }
    }

    private func fontWeightLabel(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold: return "Bold"
        case .semibold: return "Semibold"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        case .light: return "Light"
        default: return "Regular"
        }
    }

    private func updateOverride(_ newOverride: ThemeColorOverride) {
        store.themeCustomizations.setOverride(newOverride, for: themeId)
        store.save()
    }

    private func pushTheme() {
        if store.selectedTheme != themeId {
            store.selectedTheme = themeId
        }
        store.save()
        pushInProgress = true
        pushSucceeded = false
        toastManager?.show(.syncing, message: "Pushing theme to display...")
        Task {
            await connectionManager.sendThemePack(store: store, bleManager: bleManager)
            await connectionManager.sendLightSync(store: store, bleManager: bleManager)
            pushInProgress = false
            if connectionManager.connectionState == .connected {
                pushSucceeded = true
                toastManager?.show(.success, message: "Theme pushed to display")
            } else {
                toastManager?.show(.error, message: connectionManager.lastError ?? "Push failed")
            }
            try? await Task.sleep(for: .seconds(2))
            pushSucceeded = false
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isUploading = true
        uploadSuccess = false
        toastManager?.show(.syncing, message: "Uploading background image...")

        guard let rawData = try? await item.loadTransferable(type: Data.self) else {
            isUploading = false
            toastManager?.show(.error, message: "Failed to load image")
            return
        }

        let data = ImageCompressor.compress(imageData: rawData, maxDimension: 1920, quality: 0.82) ?? rawData

        let filename = "bg_\(themeId.rawValue)_\(Int(Date().timeIntervalSince1970)).jpg"
        if let url = await connectionManager.uploadBackgroundImage(imageData: data, filename: filename, store: store) {
            var o = override
            o.backgroundImageUrl = url
            o.backgroundImageFit = o.backgroundImageFit ?? "cover"
            updateOverride(o)
            uploadSuccess = true
            toastManager?.show(.success, message: "Background image uploaded")
        } else {
            toastManager?.show(.error, message: connectionManager.lastError ?? "Upload failed")
        }

        isUploading = false
        selectedPhoto = nil
    }
}
