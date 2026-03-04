import SwiftUI

struct AddAnnouncementRow: View {
    let onAdd: (String, Bool, Date?) -> Void

    @State private var newText: String = ""
    @State private var isPinned: Bool = false
    @State private var hasExpiration: Bool = false
    @State private var expirationDate: Date = Date().addingTimeInterval(86400)
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button {
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Announcement")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: DS.Spacing.sm) {
                    TextField("اكتب الإعلان هنا...", text: $newText, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .environment(\.layoutDirection, .rightToLeft)

                    Toggle("Pin Message", isOn: $isPinned)
                        .font(.subheadline)

                    Toggle("Set Expiration", isOn: $hasExpiration)
                        .font(.subheadline)

                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .font(.subheadline)
                    }

                    Button {
                        guard !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        onAdd(newText, isPinned, hasExpiration ? expirationDate : nil)
                        newText = ""
                        isPinned = false
                        hasExpiration = false
                        withAnimation(.spring(duration: 0.3)) { isExpanded = false }
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: newText.isEmpty)
                }
                .padding(DS.Spacing.sm)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: DS.Radius.md))
            }
        }
    }
}
