import SwiftUI
import SwiftUIX

struct ThemesView: View {
    @Bindable var store: AppStore
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: DS.Spacing.md) {
                ForEach(ThemeDefinition.allThemes) { theme in
                    themeCard(theme: theme)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(PremiumBackground(accentColor: store.currentTheme.palette.accent))
        .navigationTitle("Themes")
    }

    private func themeCard(theme: ThemeDefinition) -> some View {
        let isSelected = store.selectedTheme == theme.id
        let hasCustom = store.themeCustomizations.override(for: theme.id).hasOverrides
        let effectiveTheme = hasCustom ? theme.applying(override: store.themeCustomizations.override(for: theme.id)) : theme

        return VStack(spacing: 0) {
            ZStack {
                ThemePreviewThumbnail(theme: effectiveTheme)
                    .frame(height: 160)

                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                                .padding(10)
                        }
                        Spacer()
                    }
                }

                if hasCustom {
                    VStack {
                        HStack {
                            StatusChip("Customized", color: .purple, icon: "paintbrush.fill")
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                }

                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)
                }
            }
            .frame(height: 160)
            .clipShape(.rect(cornerRadius: DS.Radius.lg, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.nameEn)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Text(theme.nameAr)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        StatusChip(theme.isDark ? "Dark" : "Light", color: theme.isDark ? .indigo : .yellow)
                    }

                    HStack(spacing: 4) {
                        paletteChip(color: effectiveTheme.palette.background)
                        paletteChip(color: effectiveTheme.palette.primary)
                        paletteChip(color: effectiveTheme.palette.accent)
                        paletteChip(color: effectiveTheme.palette.textPrimary)
                        paletteChip(color: effectiveTheme.palette.surface)
                    }
                    .padding(.top, 2)
                }
                Spacer()

                VStack(spacing: 6) {
                    if isSelected {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Button("Apply") {
                            withAnimation(.spring(duration: 0.3)) {
                                store.selectedTheme = theme.id
                                store.save()
                                connectionManager.scheduleLightSync(store: store, bleManager: bleManager)
                                toastManager?.show(.success, message: "Theme applied: \(theme.nameEn)")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: store.selectedTheme)
                    }

                    NavigationLink(value: AppRoute.themeStudio(theme.id)) {
                        Label("Studio", systemImage: "slider.horizontal.below.square.and.square.filled")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.purple)
                }
            }
            .padding(DS.Spacing.md)
            .background(Color.white.opacity(0.08))
        }
        .clipShape(.rect(cornerRadius: DS.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : .black.opacity(0.06), radius: isSelected ? 12 : 8, y: 4)
    }

    private func paletteChip(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(.quaternary, lineWidth: 0.5))
    }
}

struct ThemeDetailView: View {
    @Bindable var store: AppStore
    let themeId: ThemeId
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    private var theme: ThemeDefinition {
        let base = ThemeDefinition.theme(for: themeId)
        let override = store.themeCustomizations.override(for: themeId)
        return override.hasOverrides ? base.applying(override: override) : base
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                ThemePreviewThumbnail(theme: theme)
                    .frame(height: 220)
                    .clipShape(.rect(cornerRadius: DS.Radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.xl)
                            .strokeBorder(theme.palette.accent.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: theme.palette.accent.opacity(0.12), radius: 16, y: 6)

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    SectionHeader(title: "Palette", icon: "paintpalette.fill", color: .orange)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                        colorSwatch("BG", color: theme.palette.background)
                        colorSwatch("Surface", color: theme.palette.surface)
                        colorSwatch("Primary", color: theme.palette.primary)
                        colorSwatch("Accent", color: theme.palette.accent)
                        colorSwatch("Text", color: theme.palette.textPrimary)
                    }
                }
                .padding(DS.Spacing.md)
                .glassLayer(.card)
                .elevation(.level2)

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    SectionHeader(title: "Properties", icon: "slider.horizontal.3", color: .blue)
                    VStack(spacing: DS.Spacing.xs) {
                        propertyRow("Contrast Ratio", value: String(format: "%.1f:1", theme.contrastRatio))
                        propertyRow("Table Density", value: theme.tokens.tableDensity.displayName)
                        propertyRow("Pattern", value: patternName(theme.backgroundPattern))
                        propertyRow("Elevation", value: elevationName(theme.layers.cardElevation))
                        propertyRow("Dark Mode", value: theme.isDark ? "Yes" : "No")
                        propertyRow("Vignette", value: vignetteName(theme.layers.vignetteStyle))
                        propertyRow("Shimmer", value: theme.layers.hasShimmer ? "Yes" : "No")
                        if store.themeCustomizations.override(for: themeId).hasOverrides {
                            propertyRow("Custom Colors", value: "Yes")
                        }
                    }
                }
                .padding(DS.Spacing.md)
                .glassLayer(.card)
                .elevation(.level2)

                NavigationLink(value: AppRoute.themeStudio(themeId)) {
                    Label("Open Theme Studio", systemImage: "slider.horizontal.below.square.and.square.filled")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)

                if store.selectedTheme != themeId {
                    Button {
                        withAnimation {
                            store.selectedTheme = themeId
                            store.save()
                            toastManager?.show(.syncing, message: "Applying theme...")
                            Task {
                                await connectionManager.sendThemePack(store: store, bleManager: bleManager)
                                if connectionManager.connectionState == .connected {
                                    toastManager?.show(.success, message: "Theme applied & pushed")
                                } else {
                                    toastManager?.show(.info, message: "Theme saved locally")
                                }
                            }
                        }
                    } label: {
                        Text("Apply Theme")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: store.selectedTheme)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Currently Active")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
        }
        .background(PremiumBackground(accentColor: store.currentTheme.palette.accent))
        .navigationTitle(theme.nameEn)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func colorSwatch(_ label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary, lineWidth: 1)
                )
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func propertyRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.vertical, 2)
    }

    private func patternName(_ pattern: BackgroundPattern) -> String {
        switch pattern {
        case .geometricStars: return "Geometric Stars"
        case .arabesque: return "Arabesque"
        case .minimal: return "Minimal"
        case .none: return "None"
        case .reliefStarfield: return "Relief Starfield"
        case .archMosaic: return "Arch Mosaic"
        case .hexGrid: return "Hex Grid"
        case .glassTile: return "Glass Tile"
        case .ledMatrix: return "LED Matrix"
        case .mosqueSilhouette: return "Mosque Silhouette"
        }
    }

    private func elevationName(_ style: ElevationStyle) -> String {
        switch style {
        case .flat: return "Flat"
        case .raised: return "Raised"
        case .inset: return "Inset"
        case .floating: return "Floating"
        case .glassmorphic: return "Glassmorphic"
        case .neumorphic: return "Neumorphic"
        }
    }

    private func vignetteName(_ style: VignetteStyle) -> String {
        switch style {
        case .none: return "None"
        case .radialDark: return "Radial Dark"
        case .radialLight: return "Radial Light"
        case .topFade: return "Top Fade"
        case .bottomFade: return "Bottom Fade"
        case .edgeBurn: return "Edge Burn"
        }
    }
}
