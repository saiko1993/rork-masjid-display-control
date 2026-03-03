import SwiftUI

struct FocusRingModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    let cornerRadius: CGFloat
    @State private var glowPulse: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        color.opacity(isActive ? (glowPulse ? 0.3 : 0.12) : 0),
                        lineWidth: isActive ? 1 : 0
                    )
                    .shadow(color: color.opacity(isActive ? 0.15 : 0), radius: 6)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowPulse)
            )
            .scaleEffect(isActive ? 1.005 : 1.0)
            .animation(DSAnimation.softEase, value: isActive)
            .onAppear { glowPulse = isActive }
            .onChange(of: isActive) { _, newVal in glowPulse = newVal }
    }
}

struct VibrancyTextModifier: ViewModifier {
    let isActive: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isActive ? color : .primary)
            .shadow(color: isActive ? color.opacity(0.25) : .clear, radius: 4)
    }
}

struct ErrorFocusModifier: ViewModifier {
    let isError: Bool
    @State private var shake: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .strokeBorder(.red.opacity(isError ? 0.4 : 0), lineWidth: 1)
            )
            .offset(x: shake ? -3 : 0)
            .onChange(of: isError) { _, newVal in
                guard newVal else { return }
                withAnimation(.spring(duration: 0.08).repeatCount(4, autoreverses: true)) {
                    shake = true
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    shake = false
                }
            }
    }
}

extension View {
    func focusRing(isActive: Bool, color: Color = .cyan, cornerRadius: CGFloat = DS.Radius.xl) -> some View {
        modifier(FocusRingModifier(isActive: isActive, color: color, cornerRadius: cornerRadius))
    }

    func vibrancyText(isActive: Bool, color: Color = .cyan) -> some View {
        modifier(VibrancyTextModifier(isActive: isActive, color: color))
    }

    func errorFocus(isError: Bool) -> some View {
        modifier(ErrorFocusModifier(isError: isError))
    }
}
