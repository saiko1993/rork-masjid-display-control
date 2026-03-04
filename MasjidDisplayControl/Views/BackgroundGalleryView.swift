import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct BackgroundGalleryView: View {
    @Bindable var store: AppStore
    let backgroundManager: BackgroundManager
    var toastManager: ToastManager?

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker: Bool = false
    @State private var showURLInput: Bool = false
    @State private var customURL: String = ""
    @State private var customName: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: DSTokens.Grid.sectionSpacing) {
                enableToggleSection
                if store.backgroundConfig.enabled {
                    intensitySection
                    backgroundTypeSection
                    activePreviewSection
                    galleryGrid
                    settingsSection
                    ambientEffectsSection
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(DepthStack(accentColor: DSTokens.Palette.accent) { Color.clear })
        .navigationTitle("Background Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let asset = await backgroundManager.saveImageFromPhotoPicker(item: item, name: "Custom Photo") {
                    store.backgroundConfig.addAsset(asset)
                    store.backgroundConfig.activeBackgroundId = asset.id
                    store.backgroundConfig.backgroundType = .photo
                    backgroundManager.loadImage(for: asset)
                    store.save()
                    toastManager?.show(.success, message: "Photo added")
                }
                selectedPhoto = nil
            }
        }
        .sheet(isPresented: $showURLInput) {
            urlInputSheet
        }
        .onAppear {
            backgroundManager.ensureStockAssets(in: &store.backgroundConfig)
            if let active = store.backgroundConfig.activeBackground, active.type == .photo {
                backgroundManager.loadImage(for: active)
            }
        }
    }

    private var enableToggleSection: some View {
        DSCard {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(DSTokens.Palette.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18))
                            .foregroundStyle(DSTokens.Palette.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Background")
                            .font(.subheadline.weight(.semibold))
                        Text("Photo, video, or animated backgrounds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Toggle("", isOn: $store.backgroundConfig.enabled)
                    .labelsHidden()
                    .tint(DSTokens.Palette.accent)
                    .onChange(of: store.backgroundConfig.enabled) { _, _ in
                        store.save()
                    }
            }
        }
    }

    private var intensitySection: some View {
        DSSection("Intensity", icon: "dial.low.fill", color: DSTokens.Palette.warmAmber) {
            HStack(spacing: DSTokens.Grid.chipSpacing) {
                ForEach(BackgroundIntensity.allCases, id: \.self) { level in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.backgroundConfig.applyIntensity(level)
                            store.save()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: level.icon)
                                .font(.system(size: 18))
                            Text(level.displayName)
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            store.backgroundConfig.intensity == level
                                ? AnyShapeStyle(DSTokens.Palette.warmAmber.opacity(0.2))
                                : AnyShapeStyle(.ultraThinMaterial)
                        )
                        .foregroundStyle(
                            store.backgroundConfig.intensity == level
                                ? DSTokens.Palette.warmAmber
                                : .secondary
                        )
                        .clipShape(.rect(cornerRadius: DS.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .strokeBorder(
                                    store.backgroundConfig.intensity == level
                                        ? DSTokens.Palette.warmAmber.opacity(0.3)
                                        : .clear,
                                    lineWidth: 0.5
                                )
                        )
                    }
                }
            }
        }
    }

    private var backgroundTypeSection: some View {
        DSSection("Background Type", icon: "square.stack.3d.up.fill", color: DSTokens.Palette.deepBlue) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSTokens.Grid.chipSpacing) {
                    ForEach(BackgroundType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                store.backgroundConfig.backgroundType = type
                                store.save()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type.icon)
                                    .font(.caption2.weight(.bold))
                                Text(type.displayName)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                store.backgroundConfig.backgroundType == type
                                    ? AnyShapeStyle(DSTokens.Palette.accent.opacity(0.2))
                                    : AnyShapeStyle(.ultraThinMaterial)
                            )
                            .foregroundStyle(
                                store.backgroundConfig.backgroundType == type
                                    ? DSTokens.Palette.accent
                                    : .secondary
                            )
                            .clipShape(.capsule)
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        store.backgroundConfig.backgroundType == type
                                            ? DSTokens.Palette.accent.opacity(0.3)
                                            : .clear,
                                        lineWidth: 0.5
                                    )
                            )
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    @ViewBuilder
    private var activePreviewSection: some View {
        if let active = store.backgroundConfig.activeBackground {
            DSCard(glow: DSTokens.Palette.accent) {
                VStack(spacing: DS.Spacing.sm) {
                    HStack {
                        Text("Active Background")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if active.isStock {
                                Text("STOCK")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(DSTokens.Palette.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(DSTokens.Palette.accent.opacity(0.15))
                                    .clipShape(.capsule)
                            }
                            Text(active.source.rawValue.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    backgroundPreviewThumbnail(for: active)
                        .frame(height: 140)
                        .clipShape(.rect(cornerRadius: DS.Radius.md))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(active.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text(active.type.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if backgroundManager.isLoadingImage {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }
        }
    }

    private var galleryGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                SectionHeader(title: "Gallery", icon: "photo.stack.fill", color: DSTokens.Palette.warmAmber)
                Spacer()
                if store.backgroundConfig.backgroundType == .photo {
                    Menu {
                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("From Photo Library", systemImage: "photo.on.rectangle")
                        }
                        Button {
                            showURLInput = true
                        } label: {
                            Label("From URL", systemImage: "link")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DSTokens.Palette.accent)
                    }
                }
            }

            let filteredGallery = filteredAssets
            if filteredGallery.isEmpty {
                DSCard {
                    VStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No backgrounds for this type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DSTokens.Grid.cardSpacing) {
                    ForEach(filteredGallery) { asset in
                        galleryItem(asset)
                    }
                }
            }
        }
    }

    private var filteredAssets: [BackgroundAsset] {
        let type = store.backgroundConfig.backgroundType
        if type == .solid { return [] }
        return store.backgroundConfig.gallery.filter { $0.type == type }
    }

    private func galleryItem(_ asset: BackgroundAsset) -> some View {
        let isActive = store.backgroundConfig.activeBackgroundId == asset.id

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                store.backgroundConfig.activeBackgroundId = asset.id
                store.backgroundConfig.backgroundType = asset.type
                if asset.type == .photo {
                    backgroundManager.loadImage(for: asset)
                }
                store.save()
            }
        } label: {
            VStack(spacing: 0) {
                backgroundPreviewThumbnail(for: asset)
                    .frame(height: 100)
                    .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))

                HStack(spacing: 4) {
                    Text(asset.name)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if !asset.isStock {
                        Button {
                            backgroundManager.deleteAsset(asset)
                            store.backgroundConfig.removeAsset(id: asset.id)
                            store.backgroundConfig.ensureFallback()
                            store.save()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .strokeBorder(
                        isActive ? DSTokens.Palette.accent.opacity(0.5) : .clear,
                        lineWidth: isActive ? 2 : 0
                    )
            )
            .elevation(isActive ? .level3 : .level1, color: isActive ? DSTokens.Palette.accent : .black)
        }
        .buttonStyle(PressEffectStyle())
    }

    @ViewBuilder
    private func backgroundPreviewThumbnail(for asset: BackgroundAsset) -> some View {
        switch asset.type {
        case .photo:
            if let thumb = backgroundManager.loadThumbnail(for: asset) {
                Color(.secondarySystemBackground)
                    .overlay {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
            } else if let urlString = asset.sourceURL, let url = URL(string: urlString) {
                Color(.secondarySystemBackground)
                    .overlay {
                        WebImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView().controlSize(.small)
                        }
                        .allowsHitTesting(false)
                    }
            } else {
                Color(.secondarySystemBackground)
                    .overlay {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
        case .gif:
            Color(.secondarySystemBackground)
                .overlay {
                    if let urlString = asset.sourceURL, let url = URL(string: urlString) {
                        WebImage(url: url, isAnimating: .constant(true)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView().controlSize(.small)
                        }
                        .allowsHitTesting(false)
                    } else {
                        Image(systemName: "livephoto")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
        case .video:
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12)
                VStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.4))
                    if asset.isStock {
                        Text("Stock")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
        case .motion:
            ZStack {
                if let preset = asset.motionPreset {
                    motionPreviewGradient(preset)
                } else {
                    Color(red: 0.05, green: 0.05, blue: 0.12)
                }
                Image(systemName: asset.motionPreset?.icon ?? "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        case .solid:
            Color(red: 0.05, green: 0.05, blue: 0.12)
        }
    }

    private func motionPreviewGradient(_ preset: MotionPresetType) -> some View {
        LinearGradient(
            colors: {
                switch preset {
                case .starfield:
                    return [Color(red: 0.02, green: 0.02, blue: 0.08), Color(red: 0.05, green: 0.03, blue: 0.12)]
                case .crescentGlow:
                    return [Color(red: 0.03, green: 0.03, blue: 0.10), Color(red: 0.08, green: 0.06, blue: 0.18)]
                case .floatingLanterns:
                    return [Color(red: 0.04, green: 0.03, blue: 0.10), Color(red: 0.08, green: 0.05, blue: 0.16)]
                case .gentleClouds:
                    return [Color(red: 0.05, green: 0.06, blue: 0.15), Color(red: 0.03, green: 0.04, blue: 0.10)]
                case .mosqueSilhouetteFog:
                    return [Color(red: 0.03, green: 0.03, blue: 0.08), Color(red: 0.06, green: 0.05, blue: 0.12)]
                }
            }(),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var settingsSection: some View {
        DSSection("Fine Tuning", icon: "slider.horizontal.3", color: DSTokens.Palette.softSlate) {
            VStack(spacing: DS.Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Blur Radius")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(store.backgroundConfig.blurRadius))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.backgroundConfig.blurRadius, in: 0...30, step: 1)
                        .tint(DSTokens.Palette.softSlate)
                        .onChange(of: store.backgroundConfig.blurRadius) { _, _ in store.save() }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overlay Darkness")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(store.backgroundConfig.overlayDarkness * 100))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.backgroundConfig.overlayDarkness, in: 0...0.8, step: 0.05)
                        .tint(DSTokens.Palette.softSlate)
                        .onChange(of: store.backgroundConfig.overlayDarkness) { _, _ in store.save() }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Parallax Strength")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f", store.backgroundConfig.parallaxStrength))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.backgroundConfig.parallaxStrength, in: 0...0.5, step: 0.05)
                        .tint(DSTokens.Palette.softSlate)
                        .onChange(of: store.backgroundConfig.parallaxStrength) { _, _ in store.save() }
                }
            }
        }
    }

    private var ambientEffectsSection: some View {
        DSSection("Ambient Effects", icon: "sparkles", color: DSTokens.Palette.warmAmber) {
            VStack(spacing: DS.Spacing.sm) {
                ForEach(AmbientEffect.allCases, id: \.self) { effect in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.backgroundConfig.ambientEffect = effect
                            store.save()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: ambientEffectIcon(effect))
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    store.backgroundConfig.ambientEffect == effect
                                        ? DSTokens.Palette.warmAmber
                                        : .secondary
                                )
                                .frame(width: 32, height: 32)
                                .background(
                                    store.backgroundConfig.ambientEffect == effect
                                        ? DSTokens.Palette.warmAmber.opacity(0.15)
                                        : .white.opacity(0.05)
                                )
                                .clipShape(.rect(cornerRadius: 8))

                            Text(effect.displayName)
                                .font(.subheadline)
                                .foregroundStyle(
                                    store.backgroundConfig.ambientEffect == effect
                                        ? .primary
                                        : .secondary
                                )

                            Spacer()

                            if store.backgroundConfig.ambientEffect == effect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DSTokens.Palette.warmAmber)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ambientEffectIcon(_ effect: AmbientEffect) -> String {
        switch effect {
        case .none: return "circle.slash"
        case .stars: return "star.fill"
        case .crescentGlow: return "moon.fill"
        case .lanternParticles: return "lamp.desk.fill"
        }
    }

    private var urlInputSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Image URL")
                        .font(.subheadline.weight(.medium))
                    TextField("https://...", text: $customURL)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.medium))
                    TextField("Background name", text: $customName)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    Task {
                        if let asset = await backgroundManager.saveImageFromURL(customURL, name: customName) {
                            store.backgroundConfig.addAsset(asset)
                            store.backgroundConfig.activeBackgroundId = asset.id
                            store.backgroundConfig.backgroundType = .photo
                            backgroundManager.loadImage(for: asset)
                            store.save()
                            toastManager?.show(.success, message: "Image added from URL")
                        } else {
                            toastManager?.show(.error, message: "Failed to load image")
                        }
                        showURLInput = false
                        customURL = ""
                        customName = ""
                    }
                } label: {
                    HStack {
                        if backgroundManager.isLoadingImage {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text("Add Image")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(DSTokens.Palette.accent)
                .disabled(customURL.isEmpty || backgroundManager.isLoadingImage)

                Spacer()
            }
            .padding(DS.Spacing.md)
            .navigationTitle("Add from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showURLInput = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
