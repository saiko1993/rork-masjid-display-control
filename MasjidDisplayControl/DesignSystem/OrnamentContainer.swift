import SwiftUI
import SwiftUIX

struct OrnamentContainer<Content: View>: View {
    var alignment: Alignment = .bottom
    let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
            .background {
                ZStack {
                    VisualEffectBlurView(blurStyle: .systemThickMaterialDark)
                    RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.08), .clear, .white.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(.rect(cornerRadius: DS.Radius.xxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xxl, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .elevation(.level4)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xs)
    }
}
