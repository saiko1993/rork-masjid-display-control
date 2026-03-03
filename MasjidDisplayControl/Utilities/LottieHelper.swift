import SwiftUI
import Lottie

struct LottieAnimationHelper: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0

    func makeUIView(context: Context) -> some UIView {
        let container = UIView(frame: .zero)
        let animationView = LottieAnimationView(animation: LottieAnimation.named(animationName))
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        animationView.play()
        return container
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct LottieURLAnimationHelper: UIViewRepresentable {
    let url: URL
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0

    func makeUIView(context: Context) -> some UIView {
        let container = UIView(frame: .zero)
        let animationView = LottieAnimationView()
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        LottieAnimation.loadedFrom(url: url) { animation in
            animationView.animation = animation
            animationView.play()
        }
        return container
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct SyncingAnimationView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(.cyan)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

struct ConnectedPulseAnimation: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .scaleEffect(scale)
                .opacity(opacity)

            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .frame(width: 24, height: 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.4
                opacity = 0.2
            }
        }
    }
}
