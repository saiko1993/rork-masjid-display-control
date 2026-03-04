import SwiftUI

struct AmbientStarsView: View {
    let size: CGSize
    var particleMultiplier: CGFloat = 1.0

    private var starCount: Int {
        min(120, max(20, Int(CGFloat(80) * particleMultiplier)))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 0.4
            Canvas { context, canvasSize in
                for i in 0..<starCount {
                    let seed = Double(i) * 11.37
                    let x = (sin(seed * 3.71) * 0.5 + 0.5) * canvasSize.width
                    let y = (cos(seed * 2.43) * 0.5 + 0.5) * canvasSize.height
                    let twinkle = sin(phase + seed * 1.2) * 0.5 + 0.5
                    let starSize = (sin(seed * 1.3) * 0.5 + 0.5) * 2.0 + 0.5
                    let opacity = twinkle * 0.45 + 0.1

                    context.fill(
                        Path(ellipseIn: CGRect(x: x - starSize/2, y: y - starSize/2, width: starSize, height: starSize)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

struct AmbientCrescentGlowView: View {
    let accentColor: Color
    @State private var glowScale: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.06),
                            accentColor.opacity(0.02),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(glowScale ? 1.1 : 0.92)
                .offset(x: 80, y: -120)

            Image(systemName: "moon.fill")
                .font(.system(size: 36))
                .foregroundStyle(accentColor.opacity(0.25))
                .shadow(color: accentColor.opacity(0.15), radius: 20)
                .offset(x: 80, y: -120)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                glowScale = true
            }
        }
    }
}

struct AmbientLanternView: View {
    let size: CGSize
    let accentColor: Color
    var particleMultiplier: CGFloat = 1.0

    private var count: Int {
        min(40, max(5, Int(CGFloat(10) * particleMultiplier)))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * 0.12
            Canvas { context, canvasSize in
                for i in 0..<count {
                    let seed = Double(i) * 7.19
                    let baseX = (sin(seed * 2.3) * 0.5 + 0.5) * canvasSize.width
                    let baseY = (cos(seed * 1.9) * 0.5 + 0.5) * canvasSize.height
                    let floatY = sin(phase + seed) * 6
                    let floatX = cos(phase * 0.67 + seed * 0.5) * 3
                    let particleSize = (sin(seed) * 0.5 + 0.5) * 5 + 3
                    let opacity = sin(phase * 1.25 + seed * 1.1) * 0.25 + 0.35

                    let x = baseX + floatX
                    let y = baseY + floatY

                    let glowRect = CGRect(x: x - particleSize * 1.5, y: y - particleSize * 1.5, width: particleSize * 3, height: particleSize * 3)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(opacity * 0.06))
                    )

                    let rect = CGRect(x: x - particleSize/2, y: y - particleSize/2, width: particleSize, height: particleSize)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(opacity * 0.4))
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
