import SwiftUI
import SwiftUIX

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                VStack(spacing: DS.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue.opacity(0.15), .cyan.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }

                    Text("Masjid Smart Display")
                        .font(.title.bold())

                    Text("Controller")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("v2.0.0 (MVP)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(.capsule)
                }
                .padding(.top, DS.Spacing.lg)

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    infoRow(icon: "tv.fill", title: "Purpose", value: "Configure Raspberry Pi mosque displays remotely")
                    Divider()
                    infoRow(icon: "paintpalette.fill", title: "Themes", value: "4 built-in Islamic themes with composite layers")
                    Divider()
                    infoRow(icon: "bell.fill", title: "Iqama", value: "Per-prayer iqama + Jumu'ah mode")
                    Divider()
                    infoRow(icon: "network", title: "Protocol", value: "Theme Pack + Light Sync (REST + BLE)")
                    Divider()
                    infoRow(icon: "lock.shield.fill", title: "Security", value: "Optional HMAC-SHA256 signing")
                    Divider()
                    infoRow(icon: "globe", title: "Languages", value: "Arabic & English")
                }
                .padding(DS.Spacing.md)
                .glassLayer(.card)

                VStack(spacing: DS.Spacing.xs) {
                    Text("بسم الله الرحمن الرحيم")
                        .font(.system(size: 20, design: .serif))

                    Text("May this tool serve the Muslim community")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, DS.Spacing.md)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About")
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
