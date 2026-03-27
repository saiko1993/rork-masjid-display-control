import SwiftUI

enum DSCardSize {
    case large
    case medium
    case small
    case flexible

    var minHeight: CGFloat? {
        switch self {
        case .large: return DSTokens.CardSize.largeHeight
        case .medium: return DSTokens.CardSize.mediumHeight
        case .small: return DSTokens.CardSize.smallHeight
        case .flexible: return nil
        }
    }

    var padding: CGFloat {
        switch self {
        case .large: return DSTokens.CardSize.largePadding
        case .medium: return DSTokens.CardSize.mediumPadding
        case .small: return DSTokens.CardSize.smallPadding
        case .flexible: return DSTokens.CardSize.mediumPadding
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .large: return DSTokens.CardSize.largeRadius
        case .medium: return DSTokens.CardSize.mediumRadius
        case .small: return DSTokens.CardSize.smallRadius
        case .flexible: return DSTokens.CardSize.mediumRadius
        }
    }
}

struct DSCard<Content: View>: View {
    var glow: Color? = nil
    var elevation: ElevationLevel = .level2
    var variant: GlassVariant = .card
    var size: DSCardSize = .flexible
    let content: () -> Content

    init(
        glow: Color? = nil,
        elevation: ElevationLevel = .level2,
        variant: GlassVariant = .card,
        size: DSCardSize = .flexible,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glow = glow
        self.elevation = elevation
        self.variant = variant
        self.size = size
        self.content = content
    }

    var body: some View {
        content()
            .padding(size.padding)
            .frame(minHeight: size.minHeight)
            .glassLayer(variant, glow: glow)
            .elevation(elevation)
    }
}

struct DSSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var glow: Color? = nil
    let content: () -> Content

    init(
        _ title: String,
        icon: String,
        color: Color,
        glow: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = color
        self.glow = glow
        self.content = content
    }

    var body: some View {
        DSCard(glow: glow ?? iconColor.opacity(0.15)) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                SectionHeader(title: title, icon: icon, color: iconColor)
                content()
            }
        }
    }
}
