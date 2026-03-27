import SwiftUI
import SwiftUIX

// MARK: - DSActionTileButton
// Large vertical tile button: icon on top, label below — glass card backed

struct DSActionTileButton: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    var tint: Color = DSTokens.Palette.accent
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var height: CGFloat = DSTokens.ButtonSize.tileHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(tint)
                        .frame(height: 26)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: DSTokens.ButtonSize.tileIconSize, weight: .medium))
                        .foregroundStyle(tint)
                        .symbolEffect(.bounce, value: isLoading)
                        .frame(height: 26)
                }
                Text(title)
                    .font(DSTokens.Font.tileTitle)
                    .foregroundStyle(isDisabled ? .tertiary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DSTokens.Font.tileSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                ZStack {
                    VisualEffectBlurView(blurStyle: .systemThinMaterialDark)
                    LinearGradient(
                        colors: [tint.opacity(isDisabled ? 0.02 : 0.06), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .clipShape(.rect(cornerRadius: DS.Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [tint.opacity(isDisabled ? 0.04 : 0.15), tint.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .elevation(.level1)
        }
        .buttonStyle(PressEffectStyle())
        .disabled(isDisabled || isLoading)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: isLoading)
    }
}

// MARK: - DSBottomBar
// Consistent glass bottom action bar — used in ThemeStudio, ThemeEditor, etc.

struct DSBottomBar<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.08), .white.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            content()
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.sm)
                .padding(.bottom, DS.Spacing.xs)
        }
        .background {
            ZStack {
                VisualEffectBlurView(blurStyle: .systemThickMaterialDark)
                LinearGradient(
                    colors: [.white.opacity(0.05), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - DSStatusDot
// Consistent animated status indicator dot

struct DSStatusDot: View {
    let color: Color
    var isAnimating: Bool = false
    var size: CGFloat = 10

    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            if isAnimating {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: size * (pulse ? 2.2 : 1.4), height: size * (pulse ? 2.2 : 1.4))
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
            }
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(isAnimating ? 0.5 : 0.2), radius: isAnimating ? 6 : 3)
        }
        .onAppear { pulse = isAnimating }
        .onChange(of: isAnimating) { _, val in pulse = val }
    }
}


