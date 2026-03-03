import SwiftUI
import SwiftUIX

struct DSFloatingTabBar<Tab: Hashable>: View {
    let tabs: [TabItem<Tab>]
    @Binding var selection: Tab

    struct TabItem<T: Hashable>: Identifiable {
        let id = UUID()
        let tab: T
        let title: String
        let icon: String
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            ForEach(tabs) { item in
                Button {
                    withAnimation(DSAnimation.tapSpring) {
                        selection = item.tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: selection == item.tab ? .semibold : .regular))
                            .symbolEffect(.bounce, value: selection == item.tab)
                        Text(item.title)
                            .font(.caption2.weight(selection == item.tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selection == item.tab ? DSTokens.Palette.accent : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(
                        selection == item.tab
                            ? AnyShapeStyle(DSTokens.Palette.accent.opacity(0.08))
                            : AnyShapeStyle(.clear)
                    )
                    .clipShape(.rect(cornerRadius: DS.Radius.md))
                }
                .sensoryFeedback(.selection, trigger: selection)
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs)
        .glassLayer(.tabBar)
        .padding(.horizontal, DS.Spacing.lg)
    }
}
