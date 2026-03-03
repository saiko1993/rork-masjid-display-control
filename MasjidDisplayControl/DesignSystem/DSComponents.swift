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

// MARK: - DSInfoRow
// Consistent label + value row used in diagnostics, settings info

struct DSInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
    }
}

// MARK: - DSMonoBlock
// Monospaced code block with optional copy button

struct DSMonoBlock: View {
    let code: String
    var onCopy: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(code)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.sm)
                .background(.white.opacity(0.05))
                .clipShape(.rect(cornerRadius: DS.Radius.sm))

            if let copy = onCopy {
                Button(action: copy) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .controlSize(.small)
            }
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

// MARK: - DSChip (enhanced StatusChip)
// Elevated version of StatusChip with optional border + elevation

struct DSChip: View {
    let text: String
    let color: Color
    var icon: String? = nil
    var showBorder: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundStyle(color)
        .clipShape(.capsule)
        .overlay(
            Capsule()
                .strokeBorder(showBorder ? color.opacity(0.2) : .clear, lineWidth: 0.5)
        )
    }
}
