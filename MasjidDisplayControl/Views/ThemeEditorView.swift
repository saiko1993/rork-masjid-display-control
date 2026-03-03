import SwiftUI
import PhotosUI
import SwiftUIX
import SDWebImageSwiftUI

struct ThemeEditorView: View {
    @Bindable var store: AppStore
    let themeId: ThemeId
    @State private var connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isUploading: Bool = false
    @State private var uploadSuccess: Bool = false
    @State private var isPushing: Bool = false

    init(store: AppStore, themeId: ThemeId, connectionManager: ConnectionManager, bleManager: BLEManager, toastManager: ToastManager? = nil) {
        self.store = store
        self.themeId = themeId
        self._connectionManager = State(initialValue: connectionManager)
        self.bleManager = bleManager
        self.toastManager = toastManager
    }

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
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                livePreviewCard
                paletteSection
                gradientSection
                layerControlsSection
                backgroundImageSection
                actionsSection
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: store.currentTheme.palette.accent) { Color.clear })
        .navigationTitle("Edit: \(baseTheme.nameEn)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.save()
                    toastManager?.show(.syncing, message: "Pushing theme...")
                    Task {
                        await connectionManager.sendThemePack(store: store, bleManager: bleManager)
                        if connectionManager.connectionState == .connected {
                            toastManager?.show(.success, message: "Theme pushed")
                        } else {
                            toastManager?.show(.info, message: "Saved locally")
                        }
                    }
                } label: {
                    Label("Push", systemImage: "arrow.up.circle.fill")
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task { await handlePhotoSelection(newItem) }
        }
    }

    private var livePreviewCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Live Preview", icon: "eye.fill", color: .purple)
            ThemePreviewThumbnail(theme: effectiveTheme)
                .frame(height: 180)
                .clipShape(.rect(cornerRadius: DS.Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xl)
                        .strokeBorder(effectiveTheme.palette.accent.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: effectiveTheme.palette.accent.opacity(0.12), radius: 16, y: 6)
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Colors", icon: "paintpalette.fill", color: .orange)

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
            colorRow("Text", hex: override.textPrimaryHex, defaultColor: baseTheme.palette.textPrimary) { hex in
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
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var gradientSection: some View {
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
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var layerControlsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Layer Controls", icon: "slider.horizontal.3", color: .indigo)

            VStack(spacing: DS.Spacing.xs) {
                sliderRow("Pattern Opacity", value: override.patternOpacity ?? Double(baseTheme.layers.patternOpacity), range: 0...0.5) { val in
                    var o = override; o.patternOpacity = val; updateOverride(o)
                }
                sliderRow("Vignette", value: override.vignetteIntensity ?? Double(baseTheme.layers.vignetteIntensity), range: 0...1) { val in
                    var o = override; o.vignetteIntensity = val; updateOverride(o)
                }
                sliderRow("Glow Radius", value: override.countdownGlowRadius ?? Double(baseTheme.layers.countdownGlowRadius), range: 0...30) { val in
                    var o = override; o.countdownGlowRadius = val; updateOverride(o)
                }
            }

            HStack(spacing: DS.Spacing.xs) {
                layerInfoChip("Pattern", value: PayloadBuilder.patternString(baseTheme.backgroundPattern))
                layerInfoChip("Vignette", value: PayloadBuilder.vignetteString(baseTheme.layers.vignetteStyle))
                layerInfoChip("Elevation", value: PayloadBuilder.elevationString(baseTheme.layers.cardElevation))
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var backgroundImageSection: some View {
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
                            ProgressView().controlSize(.small)
                        }
                }
                .indicator(.activity)
                .transition(.fade(duration: 0.3))
                .frame(height: 100)
                .clipShape(.rect(cornerRadius: DS.Radius.md))

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Image set")
                        .font(.subheadline)
                    Spacer()
                    Button("Remove") {
                        var o = override
                        o.backgroundImageUrl = nil
                        o.backgroundImageFit = nil
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
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: DS.Radius.md))
            }
            .disabled(isUploading)

            if uploadSuccess {
                Label("Image uploaded successfully!", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            Text("Upload to Raspberry Pi server. Image will be resized to fit display.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var actionsSection: some View {
        VStack(spacing: DS.Spacing.sm) {
            if override.hasOverrides {
                Button {
                    withAnimation {
                        store.themeCustomizations.resetOverride(for: themeId)
                        store.save()
                    }
                } label: {
                    Label("Reset to Default", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Button {
                if store.selectedTheme != themeId {
                    store.selectedTheme = themeId
                }
                store.save()
                isPushing = true
                toastManager?.show(.syncing, message: "Pushing theme to display...")
                Task {
                    await connectionManager.sendThemePack(store: store, bleManager: bleManager)
                    isPushing = false
                    if connectionManager.connectionState == .connected {
                        toastManager?.show(.success, message: "Theme pushed to display")
                    } else {
                        toastManager?.show(.info, message: "Theme saved locally")
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isPushing {
                        ProgressView().controlSize(.small).tint(.white)
                    }
                    Label(isPushing ? "Pushing..." : "Save & Push to Display", systemImage: "arrow.up.circle.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isPushing)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: store.saveConfirmation)
        }
    }

    private func colorRow(_ label: String, hex: String?, defaultColor: Color, onChange: @escaping (String?) -> Void) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()

            let currentColor: Color = Color(hexString: hex) ?? defaultColor

            ColorPicker("", selection: Binding<Color>(
                get: { currentColor },
                set: { newColor in
                    onChange(newColor.toHexString)
                }
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

    private func layerInfoChip(_ label: String, value: String) -> some View {
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
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: DS.Radius.sm))
    }

    private func updateOverride(_ newOverride: ThemeColorOverride) {
        store.themeCustomizations.setOverride(newOverride, for: themeId)
        store.save()
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isUploading = true
        uploadSuccess = false
        toastManager?.show(.syncing, message: "Uploading background...")

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            isUploading = false
            toastManager?.show(.error, message: "Failed to load image")
            return
        }

        let filename = "bg_\(themeId.rawValue)_\(Int(Date().timeIntervalSince1970)).jpg"
        if let url = await connectionManager.uploadBackgroundImage(imageData: data, filename: filename, store: store) {
            var o = override
            o.backgroundImageUrl = url
            o.backgroundImageFit = o.backgroundImageFit ?? "cover"
            updateOverride(o)
            uploadSuccess = true
            toastManager?.show(.success, message: "Background uploaded")
        } else {
            toastManager?.show(.error, message: "Upload failed")
        }

        isUploading = false
        selectedPhoto = nil
    }
}
