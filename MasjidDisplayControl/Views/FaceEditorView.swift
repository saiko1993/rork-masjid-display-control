import SwiftUI
import Combine
import PhotosUI
import SwiftUIX
import SDWebImageSwiftUI

enum FaceEditorTab: String, CaseIterable {
    case components = "Components"
    case theme = "Theme"
    case colors = "Colors"
    case background = "Background"
    case pattern = "Pattern"
    case typography = "Typography"
    case ticker = "Ticker"

    var icon: String {
        switch self {
        case .components: return "square.grid.3x3.fill"
        case .theme: return "paintpalette.fill"
        case .colors: return "eyedropper.halffull"
        case .background: return "photo.fill"
        case .pattern: return "square.grid.3x3.topleft.filled"
        case .typography: return "textformat.size"
        case .ticker: return "text.line.first.and.arrowtriangle.forward"
        }
    }
}

struct FaceEditorView: View {
    @Bindable var store: AppStore
    let faceId: FaceId
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    @State private var selectedTab: FaceEditorTab = .components
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isUploading: Bool = false
    @State private var pushInProgress: Bool = false
    @State private var pushSucceeded: Bool = false
    @State private var previewTime: Date = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var themeId: ThemeId { store.faceConfig.themeId }

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
            livePreview
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
        .background(PremiumBackground(accentColor: effectiveTheme.palette.accent))
        .navigationTitle(faceId.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActions
        }
        .onReceive(timer) { previewTime = $0 }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await handlePhotoSelection(newItem) }
        }
        .onAppear {
            if store.faceConfig.faceId != faceId {
                store.faceConfig.faceId = faceId
                let template = FaceTemplate.face(for: faceId)
                store.faceConfig.enabledComponents = template.defaultComponents
                store.faceConfig.themeId = faceId.defaultThemeId
            }
        }
    }

    // MARK: - Live Preview

    private var livePreview: some View {
        GeometryReader { geo in
            let previewWidth = geo.size.width - DS.Spacing.md * 2
            let previewHeight = previewWidth * 9 / 16

            FaceRendererView(
                store: store,
                faceConfig: store.faceConfig,
                screenWidth: 1920,
                screenHeight: 1080,
                now: previewTime
            )
            .frame(width: 1920, height: 1080)
            .scaleEffect(previewWidth / 1920)
            .frame(width: previewWidth, height: previewHeight)
            .clipShape(.rect(cornerRadius: DS.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .strokeBorder(effectiveTheme.palette.accent.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: effectiveTheme.palette.accent.opacity(0.1), radius: 12, y: 4)
            .frame(maxWidth: .infinity)
        }
        .frame(height: (UIScreen.main.bounds.width - DS.Spacing.md * 2) * 9 / 16 + DS.Spacing.sm)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(FaceEditorTab.allCases, id: \.self) { tab in
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
        .padding(.vertical, DS.Spacing.xs)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .components: componentsTab
        case .theme: themeTab
        case .colors: colorsTab
        case .background: backgroundTab
        case .pattern: patternTab
        case .typography: typographyTab
        case .ticker: tickerTab
        }
    }

    // MARK: - Components Tab

    private var componentsTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Toggle Components", icon: "square.grid.3x3.fill", color: .teal)

            Text("Enable or disable display elements for this face.")
                .font(.caption)
                .foregroundStyle(.secondary)

            let template = FaceTemplate.face(for: faceId)
            ForEach(FaceComponentId.allCases, id: \.self) { comp in
                if template.supportedComponents.contains(comp) {
                    componentToggleRow(comp)
                }
            }

            Divider().padding(.vertical, DS.Spacing.xs)

            Button {
                withAnimation {
                    store.faceConfig.enabledComponents = template.defaultComponents
                    store.save()
                }
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding(DS.Spacing.md)
        .glassPanel()
    }

    private func componentToggleRow(_ comp: FaceComponentId) -> some View {
        let isEnabled = store.faceConfig.enabledComponents.contains(comp)
        return HStack(spacing: DS.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? Color.teal.opacity(0.15) : Color.white.opacity(0.04))
                    .frame(width: 36, height: 36)
                Image(systemName: comp.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isEnabled ? .teal : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(comp.displayName)
                    .font(.subheadline.weight(.medium))
                Text(comp.displayNameAr)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { on in
                    withAnimation(.spring(duration: 0.2)) {
                        if on {
                            store.faceConfig.enabledComponents.insert(comp)
                        } else {
                            store.faceConfig.enabledComponents.remove(comp)
                        }
                        store.save()
                    }
                }
            ))
            .labelsHidden()
            .tint(.teal)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Theme Tab

    private var themeTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Select Theme", icon: "paintpalette.fill", color: .purple)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                ForEach(ThemeDefinition.allThemes) { theme in
                    let isActive = themeId == theme.id
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.faceConfig.themeId = theme.id
                            store.selectedTheme = theme.id
                            store.save()
                        }
                    } label: {
                        VStack(spacing: 0) {
                            ThemePreviewThumbnail(theme: theme)
                                .frame(height: 70)
                                .clipShape(.rect(cornerRadius: 10))

                            Text(theme.nameEn)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.primary)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.04))
                        }
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isActive ? Color.purple : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassPanel()
    }

    // MARK: - Colors Tab

    private var colorsTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Color Overrides", icon: "eyedropper.halffull", color: .orange)

            colorRow("Background", hex: override.backgroundHex, defaultColor: baseTheme.palette.background) { hex in
                var o = override; o.backgroundHex = hex; updateOverride(o)
            }
            colorRow("Surface", hex: override.surfaceHex, defaultColor: baseTheme.palette.surface) { hex in
                var o = override; o.surfaceHex = hex; updateOverride(o)
            }
            colorRow("Primary", hex: override.primaryHex, defaultColor: baseTheme.palette.primary) { hex in
                var o = override; o.primaryHex = hex; updateOverride(o)
            }
            colorRow("Accent", hex: override.accentHex, defaultColor: baseTheme.palette.accent) { hex in
                var o = override; o.accentHex = hex; updateOverride(o)
            }
            colorRow("Text Primary", hex: override.textPrimaryHex, defaultColor: baseTheme.palette.textPrimary) { hex in
                var o = override; o.textPrimaryHex = hex; updateOverride(o)
            }
            colorRow("Text Secondary", hex: override.textSecondaryHex, defaultColor: baseTheme.palette.textSecondary) { hex in
                var o = override; o.textSecondaryHex = hex; updateOverride(o)
            }

            Divider().padding(.vertical, DS.Spacing.xs)

            if baseTheme.layers.gradientStops.count > 0 {
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
            }

            if override.hasOverrides {
                Button {
                    withAnimation {
                        store.themeCustomizations.resetOverride(for: themeId)
                        store.save()
                    }
                } label: {
                    Label("Reset All Colors", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(DS.Spacing.md)
        .glassPanel()
    }

    // MARK: - Background Tab

    private var backgroundTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Background Image", icon: "photo.fill", color: .green)

            if let url = override.backgroundImageUrl, !url.isEmpty {
                WebImage(url: URL(string: url)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .fill(Color.white.opacity(0.06))
                        .overlay { ProgressView().controlSize(.small) }
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
                .frame(height: 120)
                .clipShape(.rect(cornerRadius: DS.Radius.md))

                HStack {
                    Text("Fit Mode")
                        .font(.subheadline)
                    Spacer()
                    Picker("Fit", selection: Binding(
                        get: { override.backgroundImageFit ?? "cover" },
                        set: { val in var o = override; o.backgroundImageFit = val; updateOverride(o) }
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

                Button("Remove Background") {
                    var o = override
                    o.backgroundImageUrl = nil
                    o.backgroundImageFit = nil
                    o.backgroundImageBlur = nil
                    updateOverride(o)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.red)
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 8) {
                    if isUploading {
                        ProgressView().controlSize(.small)
                        Text("Uploading...")
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

            sliderRow("Vignette", value: override.vignetteIntensity ?? Double(baseTheme.layers.vignetteIntensity), range: 0...1) { val in
                var o = override; o.vignetteIntensity = val; updateOverride(o)
            }
        }
        .padding(DS.Spacing.md)
        .glassPanel()
    }

    // MARK: - Pattern Tab

    private var patternTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Pattern Overlay", icon: "square.grid.3x3.topleft.filled", color: .indigo)

            sliderRow("Pattern Opacity", value: override.patternOpacity ?? Double(baseTheme.layers.patternOpacity), range: 0...0.5) { val in
                var o = override; o.patternOpacity = val; updateOverride(o)
            }

            colorRow("Pattern Color", hex: override.patternColorHex, defaultColor: baseTheme.palette.primary) { hex in
                var o = override; o.patternColorHex = hex; updateOverride(o)
            }

            sliderRow("Glow Radius", value: override.countdownGlowRadius ?? Double(baseTheme.layers.countdownGlowRadius), range: 0...30) { val in
                var o = override; o.countdownGlowRadius = val; updateOverride(o)
            }

            infoRow("Pattern Type", value: PayloadBuilder.patternString(baseTheme.backgroundPattern))
            infoRow("Elevation Style", value: PayloadBuilder.elevationString(baseTheme.layers.cardElevation))
            infoRow("Glow Style", value: PayloadBuilder.glowString(baseTheme.layers.glowStyle))
        }
        .padding(DS.Spacing.md)
        .glassPanel()
    }

    // MARK: - Typography Tab

    private var typographyTab: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Typography", icon: "textformat.size", color: .pink)

            infoRow("Time Font", value: fontDesignLabel(baseTheme.typography.timeFontDesign))
            infoRow("Arabic Font", value: fontDesignLabel(baseTheme.typography.arabicFontDesign))
            infoRow("Time Weight", value: fontWeightLabel(baseTheme.typography.timeWeight))

            Divider().padding(.vertical, DS.Spacing.xs)

            Toggle("Large Mode (Bigger Prayer Fonts)", isOn: $store.largeMode)
                .font(.subheadline)

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

            infoRow("Font Scale Range", value: "\(String(format: "%.2f", baseTheme.tokens.minFontScale)) – \(String(format: "%.2f", baseTheme.tokens.maxFontScale))")
        }
        .padding(DS.Spacing.md)
        .glassPanel()
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
        .glassPanel()
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
                    pushFace()
                } label: {
                    HStack(spacing: 8) {
                        if pushInProgress {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: pushSucceeded ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        }
                        Text(pushSucceeded ? "Pushed!" : "Save & Push Face")
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
                Button { onChange(nil) } label: {
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
                Text(label).font(.subheadline)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(get: { value }, set: { onChange($0) }), in: range)
                .tint(.blue)
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
        }
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
        default: return "Regular"
        }
    }

    private func updateOverride(_ newOverride: ThemeColorOverride) {
        store.themeCustomizations.setOverride(newOverride, for: themeId)
        store.save()
    }

    private func pushFace() {
        store.selectedTheme = themeId
        store.save()
        pushInProgress = true
        pushSucceeded = false
        toastManager?.show(.syncing, message: "Pushing face to display...")
        Task {
            await connectionManager.sendThemePack(store: store, bleManager: bleManager)
            await connectionManager.sendLightSync(store: store, bleManager: bleManager)
            pushInProgress = false
            if connectionManager.connectionState == .connected {
                pushSucceeded = true
                toastManager?.show(.success, message: "Face pushed to display")
            } else {
                toastManager?.show(.error, message: connectionManager.lastError ?? "Push failed")
            }
            try? await Task.sleep(for: .seconds(2))
            pushSucceeded = false
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isUploading = true
        toastManager?.show(.syncing, message: "Uploading background image...")
        guard let rawData = try? await item.loadTransferable(type: Data.self) else {
            isUploading = false
            toastManager?.show(.error, message: "Failed to load image")
            return
        }
        let data = ImageCompressor.compress(imageData: rawData, maxDimension: 1920, quality: 0.82) ?? rawData
        let filename = "bg_\(faceId.rawValue)_\(Int(Date().timeIntervalSince1970)).jpg"
        if let url = await connectionManager.uploadBackgroundImage(imageData: data, filename: filename, store: store) {
            var o = override
            o.backgroundImageUrl = url
            o.backgroundImageFit = o.backgroundImageFit ?? "cover"
            updateOverride(o)
            toastManager?.show(.success, message: "Background image uploaded")
        } else {
            toastManager?.show(.error, message: connectionManager.lastError ?? "Upload failed")
        }
        isUploading = false
        selectedPhoto = nil
    }
}
