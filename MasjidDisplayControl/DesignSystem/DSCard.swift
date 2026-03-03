import SwiftUI

struct DSCard<Content: View>: View {
    var glow: Color? = nil
    var elevation: ElevationLevel = .level2
    var variant: GlassVariant = .card
    let content: () -> Content

    init(
        glow: Color? = nil,
        elevation: ElevationLevel = .level2,
        variant: GlassVariant = .card,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glow = glow
        self.elevation = elevation
        self.variant = variant
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.Spacing.md)
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
        DSCard(glow: glow ?? iconColor.opacity(0.3)) {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                SectionHeader(title: title, icon: icon, color: iconColor)
                content()
            }
        }
    }
}
