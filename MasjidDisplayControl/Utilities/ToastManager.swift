import SwiftUI
import PopupView
import SwiftUIX

nonisolated enum ToastType: Sendable {
    case success
    case error
    case info
    case syncing

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .cyan
        case .syncing: return .blue
        }
    }
}

struct ToastItem: Identifiable, Sendable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: Double

    init(type: ToastType, message: String, duration: Double = 2.5) {
        self.type = type
        self.message = message
        self.duration = duration
    }
}

@Observable
@MainActor
class ToastManager {
    var currentToast: ToastItem? = nil
    var showPopupToast: Bool = false
    private var dismissTask: Task<Void, Never>? = nil

    func show(_ type: ToastType, message: String, duration: Double = 2.5) {
        dismissTask?.cancel()
        currentToast = ToastItem(type: type, message: message, duration: duration)
        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
            showPopupToast = true
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.3)) {
                showPopupToast = false
            }
            try? await Task.sleep(for: .seconds(0.4))
            guard !Task.isCancelled else { return }
            currentToast = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) {
            showPopupToast = false
        }
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            currentToast = nil
        }
    }
}

struct PopupToastContent: View {
    let toast: ToastItem

    var body: some View {
        HStack(spacing: 10) {
            if toast.type == .syncing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            } else {
                Image(systemName: toast.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(toast.type.color)
            }

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            ZStack {
                VisualEffectBlurView(blurStyle: .systemChromeMaterialDark)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(toast.type.color.opacity(0.1))
            }
        }
        .clipShape(.rect(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(toast.type.color.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: toast.type.color.opacity(0.2), radius: 16, y: 4)
        .shadow(color: .black.opacity(0.4), radius: 10, y: 6)
        .padding(.horizontal, 16)
    }
}

struct ToastPopupModifier: ViewModifier {
    @Bindable var toastManager: ToastManager

    func body(content: Content) -> some View {
        content
            .popup(isPresented: $toastManager.showPopupToast) {
                if let toast = toastManager.currentToast {
                    PopupToastContent(toast: toast)
                }
            } customize: {
                $0
                    .type(.floater())
                    .position(.top)
                    .animation(.spring(duration: 0.4, bounce: 0.2))
                    .closeOnTapOutside(false)
                    .closeOnTap(false)
                    .autohideIn(nil)
                    .displayMode(.overlay)
            }
    }
}

extension View {
    func popupToasts(manager: ToastManager) -> some View {
        modifier(ToastPopupModifier(toastManager: manager))
    }
}

struct ToastOverlay: View {
    let toast: ToastItem?

    var body: some View {
        EmptyView()
    }
}
