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

    private var isSpinning: Bool {
        guard let cm else { return false }
        return cm.connectionState == .searching || cm.connectionState == .syncing
    }

    private var showReconnect: Bool {
        guard let cm else { return false }
        return cm.connectionState == .disconnected || cm.connectionState == .error
    }

    private var showQueue: Bool {
        guard let cm else { return false }
        return cm.pendingCount > 0
    }

    private var showPaired: Bool {
        guard let cm else { return false }
        return cm.isPaired
    }

    var body: some View {
        HStack(spacing: 6) {
            DSStatusDot(color: dotColor, isAnimating: dotColor == .green || dotColor == .blue, size: 10)
                .frame(width: 20, height: 20)

            chipView(icon: stateIcon, color: dotColor, spinning: isSpinning)
                .frame(width: 84, height: 28)

            chipView(icon: networkIcon, color: networkColor)
                .frame(width: 84, height: 28)

            if showQueue {
                queueChip(count: cm?.pendingCount ?? 0)
                    .frame(width: 84, height: 28)
            }

            Spacer(minLength: 0)

            if showReconnect {
                reconnectButton
                    .frame(width: 44, height: 44)
            }

            if showPaired {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(height: 56)
        .padding(.horizontal, DS.Spacing.md)
        .glassLayer(.ornament, glow: dotColor)
        .elevation(.level2)
    }

    private func chipView(icon: String, color: Color, spinning: Bool = false) -> some View {
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
