import SwiftUI

struct DepthStack<Content: View>: View {
    var accentColor: Color = .cyan
    var showGlow: Bool = true
    var showPattern: Bool = false
    var patternView: AnyView? = nil
    var phaseGlow: Color? = nil
    var ornament: AnyView? = nil
    let content: () -> Content

    init(
        accentColor: Color = .cyan,
        showGlow: Bool = true,
        showPattern: Bool = false,
        patternView: AnyView? = nil,
        phaseGlow: Color? = nil,
        ornament: AnyView? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accentColor = accentColor
        self.showGlow = showGlow
        self.showPattern = showPattern
        self.patternView = patternView
        self.phaseGlow = phaseGlow
        self.ornament = ornament
        self.content = content
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            if showGlow {
                glowOverlays
                    .ignoresSafeArea()
            }

            if showPattern, let pattern = patternView {
                pattern
                    .opacity(0.4)
                    .ignoresSafeArea()
            }

            vignetteLayer
                .ignoresSafeArea()

            content()

            if let glow = phaseGlow {
                phaseGlowOverlay(glow)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if let ornamentView = ornament {
                VStack {
                    Spacer()
                    ornamentView
                }
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                DSTokens.Palette.backgroundMid,
                DSTokens.Palette.backgroundDark,
                Color(red: 0.03, green: 0.03, blue: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowOverlays: some View {
        ZStack {
            RadialGradient(
                colors: [accentColor.opacity(0.025), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
            RadialGradient(
                colors: [accentColor.opacity(0.015), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 400
            )
        }
    }

    private var vignetteLayer: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.10)],
            center: .center,
            startRadius: 200,
            endRadius: 600
        )
    }

    private func phaseGlowOverlay(_ color: Color) -> some View {
        LinearGradient(
            colors: [color.opacity(0.03), .clear, .clear, color.opacity(0.015)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
