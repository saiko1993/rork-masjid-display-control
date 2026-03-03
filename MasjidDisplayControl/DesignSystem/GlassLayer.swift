import SwiftUI
import SwiftUIX

enum GlassVariant {
    case window
    case card
    case chip
    case tabBar
    case ornament

    var cornerRadius: CGFloat {
        switch self {
        case .window: return DS.Radius.xxl
        case .card: return DS.Radius.xl
        case .chip: return 100
        case .tabBar: return DS.Radius.xxl
        case .ornament: return DS.Radius.xl
        }
    }

    var borderOpacity: CGFloat {
        switch self {
        case .window: return 0.18
        case .card: return 0.15
        case .chip: return 0.12
        case .tabBar: return 0.2
        case .ornament: return 0.2
        }
    }

    var tintOpacity: CGFloat {
        switch self {
        case .window: return 0.08
        case .card: return 0.06
        case .chip: return 0.04
        case .tabBar: return 0.1
        case .ornament: return 0.08
        }
    }

    var blurStyle: UIBlurEffect.Style {
        switch self {
        case .window: return .systemUltraThinMaterialDark
        case .card: return .systemThinMaterialDark
        case .chip: return .systemUltraThinMaterialDark
        case .tabBar: return .systemChromeMaterialDark
        case .ornament: return .systemThickMaterialDark
        }
    }
}

struct GlassLayerModifier: ViewModifier {
    let variant: GlassVariant
    var tintColor: Color = .white
    var glowColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    VisualEffectBlurView(blurStyle: variant.blurStyle)

                    RoundedRectangle(cornerRadius: variant.cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(variant.tintOpacity),
                                    .clear,
                                    tintColor.opacity(variant.tintOpacity * 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    noiseOverlay
                }
            }
            .clipShape(.rect(cornerRadius: variant.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: variant.cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                tintColor.opacity(variant.borderOpacity),
                                tintColor.opacity(variant.borderOpacity * 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: (glowColor ?? .clear).opacity(glowColor != nil ? 0.04 : 0),
                radius: 8, y: 3
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

    @ViewBuilder
    private var noiseOverlay: some View {
        RoundedRectangle(cornerRadius: variant.cornerRadius, style: .continuous)
            .fill(.white.opacity(0.012))
    }
}

extension View {
    func glassLayer(_ variant: GlassVariant, tint: Color = .white, glow: Color? = nil) -> some View {
        modifier(GlassLayerModifier(variant: variant, tintColor: tint, glowColor: glow))
    }
}
