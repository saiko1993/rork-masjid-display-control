import SwiftUI

enum DSAnimation {
    static let tapSpring: Animation = .spring(duration: 0.2, bounce: 0.3)
    static let softEase: Animation = .easeInOut(duration: 0.3)
    static let fade: Animation = .easeOut(duration: 0.25)
    static let popover: Animation = .spring(duration: 0.4, bounce: 0.2)
    static let appear: Animation = .spring(duration: 0.6, bounce: 0.15)
}

struct PressEffectStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var tiltDegrees: Double = 1.5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .rotation3DEffect(
                .degrees(configuration.isPressed ? tiltDegrees : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(DSAnimation.tapSpring, value: configuration.isPressed)
    }
}

struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.4), value: configuration.isPressed)
    }
}

struct BounceButtonStyle: ButtonStyle {
    var tint: Color = DSTokens.Palette.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(duration: 0.15, bounce: 0.5), value: configuration.isPressed)
    }
}

struct FocusPulseModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    @State private var pulse: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                    .strokeBorder(color.opacity(isActive ? (pulse ? 0.25 : 0.08) : 0), lineWidth: 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            )
            .onAppear { pulse = isActive }
            .onChange(of: isActive) { _, newValue in pulse = newValue }
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(DSAnimation.appear.delay(delay), value: isVisible)
    }
}

extension View {
    func focusPulse(isActive: Bool, color: Color = .cyan) -> some View {
        modifier(FocusPulseModifier(isActive: isActive, color: color))
    }

    func staggerAppear(visible: Bool, index: Int) -> some View {
        modifier(StaggeredAppearModifier(isVisible: visible, delay: Double(index) * 0.06))
    }
}
