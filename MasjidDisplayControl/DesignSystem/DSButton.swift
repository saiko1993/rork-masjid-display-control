import SwiftUI

enum DSButtonVariant {
    case primary
    case secondary
    case destructive
    case ghost

    var tintColor: Color {
        switch self {
        case .primary: return .cyan
        case .secondary: return .white
        case .destructive: return .red
        case .ghost: return .secondary
        }
    }
}

struct DSButton: View {
    let title: String
    let icon: String?
    var variant: DSButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        variant: DSButtonVariant = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(variant == .primary ? .white : variant.tintColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(DSTokens.Font.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, DS.Spacing.md)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: DSTokens.ButtonSize.primaryHeight)
        }
        .buttonStyle(dsButtonStyle)
        .disabled(isDisabled || isLoading)
    }

    private var dsButtonStyle: some ButtonStyle {
        switch variant {
        case .primary:
            return AnyButtonStyle(DSPrimaryButtonStyle())
        case .secondary:
            return AnyButtonStyle(DSSecondaryButtonStyle())
        case .destructive:
            return AnyButtonStyle(DSDestructiveButtonStyle())
        case .ghost:
            return AnyButtonStyle(DSGhostButtonStyle())
        }
    }
}

private struct DSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.cyan, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))
            .shadow(color: .cyan.opacity(0.15), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DSAnimation.tapSpring, value: configuration.isPressed)
    }
}

private struct DSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(.white.opacity(0.08))
            .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(DSAnimation.tapSpring, value: configuration.isPressed)
    }
}

private struct DSDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.red)
            .background(.red.opacity(0.12))
            .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                    .strokeBorder(.red.opacity(0.2), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(DSAnimation.tapSpring, value: configuration.isPressed)
    }
}

private struct DSGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.secondary)
            .background(.clear)
            .clipShape(.rect(cornerRadius: DS.Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(DSAnimation.tapSpring, value: configuration.isPressed)
    }
}

struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
