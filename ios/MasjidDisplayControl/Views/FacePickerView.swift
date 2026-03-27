import SwiftUI
import SwiftUIX

struct FacePickerView: View {
    @Bindable var store: AppStore
    let connectionManager: ConnectionManager
    let bleManager: BLEManager
    var toastManager: ToastManager?

    @State private var isPushing: Bool = false

    private var activeFace: FaceConfiguration {
        store.faceConfig
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                livePreviewCard
                faceGrid
                activeInfoSection
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(PremiumBackground(accentColor: store.currentTheme.palette.accent))
        .navigationTitle("Mosque Faces")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            pushBar
        }
    }

    private var livePreviewCard: some View {
        let theme = ThemeDefinition.theme(for: activeFace.themeId)
        let overridden = store.themeCustomizations.override(for: activeFace.themeId)
        let effectiveTheme = overridden.hasOverrides ? theme.applying(override: overridden) : theme

        return FaceThumbnailView(
            faceId: activeFace.faceId,
            theme: effectiveTheme,
            isSelected: true
        )
        .frame(height: 180)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(activeFace.faceId.displayName)
                    .font(.headline)
                Text(activeFace.faceId.displayNameAr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 10))
            .padding(10)
        }
        .overlay(alignment: .topTrailing) {
            NavigationLink(value: AppRoute.faceEditor(activeFace.faceId)) {
                Label("Edit", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(.capsule)
            }
            .padding(10)
        }
    }

    private var faceGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Face Templates", icon: "rectangle.grid.2x2.fill", color: .purple)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.md) {
                ForEach(FaceId.allCases, id: \.self) { faceId in
                    let isActive = activeFace.faceId == faceId
                    let defaultTheme = ThemeDefinition.theme(for: faceId.defaultThemeId)

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.faceConfig.faceId = faceId
                            let template = FaceTemplate.face(for: faceId)
                            store.faceConfig.enabledComponents = template.defaultComponents
                            if !isActive {
                                store.faceConfig.themeId = faceId.defaultThemeId
                                store.selectedTheme = faceId.defaultThemeId
                            }
                            store.save()
                        }
                    } label: {
                        VStack(spacing: 0) {
                            FaceThumbnailView(
                                faceId: faceId,
                                theme: isActive ? ThemeDefinition.theme(for: activeFace.themeId) : defaultTheme,
                                isSelected: isActive
                            )
                            .frame(height: 110)

                            VStack(spacing: 2) {
                                Text(faceId.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(faceId.displayNameAr)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.06))
                        }
                        .clipShape(.rect(cornerRadius: DS.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .stroke(isActive ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PressButtonStyle())
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: activeFace.faceId)
                }
            }
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var activeInfoSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            SectionHeader(title: "Active Components", icon: "square.grid.3x3.fill", color: .teal)

            let components = Array(activeFace.enabledComponents).sorted { $0.rawValue < $1.rawValue }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(components, id: \.self) { comp in
                    HStack(spacing: 4) {
                        Image(systemName: comp.icon)
                            .font(.caption2)
                            .foregroundStyle(.teal)
                        Text(comp.displayName)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.teal.opacity(0.1))
                    .clipShape(.capsule)
                }
            }

            NavigationLink(value: AppRoute.faceEditor(activeFace.faceId)) {
                Label("Customize Face", systemImage: "slider.horizontal.below.square.and.square.filled")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.purple)
        }
        .padding(DS.Spacing.md)
        .glassLayer(.card)
        .elevation(.level2)
    }

    private var pushBar: some View {
        VStack(spacing: DS.Spacing.xs) {
            Divider()
            Button {
                pushFace()
            } label: {
                HStack(spacing: 8) {
                    if isPushing {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                    }
                    Text(isPushing ? "Pushing..." : "Push Face to Display")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPushing)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xs)
        }
        .background(.ultraThinMaterial)
    }

    private func pushFace() {
        isPushing = true
        toastManager?.show(.syncing, message: "Pushing face to display...")
        Task {
            await connectionManager.sendThemePack(store: store, bleManager: bleManager)
            await connectionManager.sendLightSync(store: store, bleManager: bleManager)
            isPushing = false
            if connectionManager.connectionState == .connected {
                toastManager?.show(.success, message: "Face pushed to display")
            } else {
                toastManager?.show(.error, message: connectionManager.lastError ?? "Push failed")
            }
        }
    }
}
