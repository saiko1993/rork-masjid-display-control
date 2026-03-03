import SwiftUI

struct StatusOrnamentBar: View {
    let connectionManager: ConnectionManager?
    let networkMonitor: NetworkMonitor?
    var toastManager: ToastManager?
    var store: AppStore?
    @State private var isReconnecting: Bool = false

    private var cm: ConnectionManager? { connectionManager }

    private var dotColor: Color {
        guard let cm else { return .secondary }
        switch cm.connectionState {
        case .connected: return .green
        case .searching: return .orange
        case .syncing: return .blue
        case .error: return .red
        case .disconnected: return .secondary
        }
    }

    private var stateIcon: String {
        guard let cm else { return "link" }
        switch cm.connectionState {
        case .connected: return "link"
        case .searching: return "magnifyingglass"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle.fill"
        case .disconnected: return "link.badge.plus"
        }
    }

    private var networkIcon: String {
        guard let nm = networkMonitor else { return "wifi.slash" }
        return nm.isConnected ? "wifi" : "wifi.slash"
    }

    private var networkColor: Color {
        guard let nm = networkMonitor else { return .red }
        return nm.isConnected ? .cyan : .red
    }

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            DSStatusDot(color: dotColor, isAnimating: cm?.connectionState == .connected || cm?.connectionState == .syncing, size: 10)
                .frame(width: 20, height: 20)

            fixedChip(icon: stateIcon, color: dotColor, spinning: cm?.connectionState == .searching || cm?.connectionState == .syncing)
                .frame(width: 84)

            fixedChip(icon: networkIcon, color: networkColor)
                .frame(width: 84)

            if let cm, cm.pendingCount > 0 {
                queueChip(count: cm.pendingCount)
                    .frame(width: 84)
            }

            Spacer(minLength: 0)

            if let cm, cm.connectionState == .disconnected || cm.connectionState == .error {
                reconnectButton
                    .frame(width: 44, height: 44)
            }

            if let cm, cm.isPaired {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                    .frame(width: 20)
            }
        }
        .frame(height: 56)
        .padding(.horizontal, DS.Spacing.md)
        .glassLayer(.ornament, glow: dotColor)
        .elevation(.level2)
    }

    private func fixedChip(icon: String, color: Color, spinning: Bool = false) -> some View {
        HStack(spacing: 4) {
            if spinning {
                ProgressView()
                    .controlSize(.mini)
                    .tint(color)
            } else {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.12))
        .clipShape(.capsule)
        .frame(height: 28)
    }

    private func queueChip(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "tray.full.fill")
                .font(.caption2.weight(.bold))
            Text("\(count)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .lineLimit(1)
        }
        .foregroundStyle(.orange)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.orange.opacity(0.12))
        .clipShape(.capsule)
        .frame(height: 28)
        .accessibilityLabel("Queue: \(count)")
    }

    private var reconnectButton: some View {
        Button {
            guard let cm, let store else { return }
            isReconnecting = true
            Task {
                await cm.reconnect(store: store)
                isReconnecting = false
                if cm.connectionState == .connected {
                    toastManager?.show(.success, message: "Connected")
                } else {
                    toastManager?.show(.error, message: cm.lastError ?? "Failed")
                }
            }
        } label: {
            Group {
                if isReconnecting {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.cyan)
        .disabled(isReconnecting)
    }
}
