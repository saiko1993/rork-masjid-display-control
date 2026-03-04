import SwiftUI
import SDWebImageSwiftUI
import AVFoundation

struct DynamicBackgroundRenderer: View {
    let config: BackgroundConfig
    let backgroundManager: BackgroundManager
    let accentColor: Color
    var scrollOffset: CGFloat = 0

    private var parallaxOffset: CGFloat {
        scrollOffset * config.parallaxStrength
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundLayer(size: geo.size)
                gradientOverlay
                blurGlassLayer
                ambientLayer(size: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        if !config.enabled {
            Color.clear
        } else if let active = config.activeBackground {
            switch active.type {
            case .image:
                imageBackground(asset: active, size: size)
            case .gif:
                gifBackground(asset: active, size: size)
            case .video:
                videoBackground(asset: active, size: size)
            case .motion:
                motionBackground(preset: active.motionPreset ?? .starfield, size: size)
            case .solid:
                Color.clear
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func imageBackground(asset: BackgroundAsset, size: CGSize) -> some View {
        if let loadedImage = backgroundManager.loadedImage {
            Image(uiImage: loadedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height + abs(parallaxOffset) * 2 + 40)
                .offset(y: parallaxOffset)
                .clipped()
                .allowsHitTesting(false)
        } else if let urlString = asset.sourceURL, let url = URL(string: urlString) {
            WebImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(red: 0.04, green: 0.04, blue: 0.08)
            }
            .frame(width: size.width, height: size.height + abs(parallaxOffset) * 2 + 40)
            .offset(y: parallaxOffset)
            .clipped()
            .allowsHitTesting(false)
        } else {
            Color(red: 0.04, green: 0.04, blue: 0.08)
        }
    }

    @ViewBuilder
    private func gifBackground(asset: BackgroundAsset, size: CGSize) -> some View {
        if let urlString = asset.sourceURL, let url = URL(string: urlString) {
            WebImage(url: url, isAnimating: .constant(true)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(red: 0.04, green: 0.04, blue: 0.08)
            }
            .frame(width: size.width, height: size.height + abs(parallaxOffset) * 2 + 40)
            .offset(y: parallaxOffset)
            .clipped()
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func videoBackground(asset: BackgroundAsset, size: CGSize) -> some View {
        if let urlString = asset.sourceURL, let url = URL(string: urlString) {
            VideoBackgroundView(url: url)
                .frame(width: size.width, height: size.height + abs(parallaxOffset) * 2 + 40)
                .offset(y: parallaxOffset)
                .clipped()
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func motionBackground(preset: MotionPresetType, size: CGSize) -> some View {
        MotionBackgroundView(preset: preset, size: size)
            .allowsHitTesting(false)
    }

    private var gradientOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .black.opacity(config.overlayDarkness * 0.6),
                    .black.opacity(config.overlayDarkness * 0.3),
                    .black.opacity(config.overlayDarkness * 0.5),
                    .black.opacity(config.overlayDarkness * 0.8),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    accentColor.opacity(0.03),
                    .clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
        }
        .allowsHitTesting(false)
    }

    private var blurGlassLayer: some View {
        Color.clear
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func ambientLayer(size: CGSize) -> some View {
        switch config.ambientEffect {
        case .stars:
            AmbientStarsView(size: size)
                .allowsHitTesting(false)
        case .crescentGlow:
            AmbientCrescentGlowView(accentColor: accentColor)
                .allowsHitTesting(false)
        case .lanternParticles:
            AmbientLanternView(size: size, accentColor: accentColor)
                .allowsHitTesting(false)
        case .none:
            EmptyView()
        }
    }
}

struct VideoBackgroundView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> VideoPlayerUIView {
        VideoPlayerUIView(url: url)
    }

    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {}
}

class VideoPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    init(url: URL) {
        super.init(frame: .zero)
        setupPlayer(url: url)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayer(url: URL) {
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        playerLayer = layer
        player = queuePlayer
        queuePlayer.play()

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    @objc private func appDidBecomeActive() {
        player?.play()
    }

    @objc private func appWillResignActive() {
        player?.pause()
    }

    deinit {
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
}

struct MotionBackgroundView: View {
    let preset: MotionPresetType
    let size: CGSize

    var body: some View {
        switch preset {
        case .starfield:
            StarfieldView(size: size)
        case .crescentGlow:
            CrescentGlowMotionView(size: size)
        case .floatingLanterns:
            FloatingLanternsMotionView(size: size)
        case .gentleClouds:
            GentleCloudsMotionView(size: size)
        case .mosqueSilhouetteFog:
            MosqueFogMotionView(size: size)
        }
    }
}

struct StarfieldView: View {
    let size: CGSize
    @State private var phase: Double = 0

    var body: some View {
        Canvas { context, canvasSize in
            let starCount = 120
            for i in 0..<starCount {
                let seed = Double(i) * 7.31
                let x = (sin(seed * 3.17) * 0.5 + 0.5) * canvasSize.width
                let y = (cos(seed * 2.83) * 0.5 + 0.5) * canvasSize.height
                let twinkle = sin(phase * 0.3 + seed) * 0.5 + 0.5
                let starSize = (sin(seed * 1.7) * 0.5 + 0.5) * 2.5 + 0.5
                let opacity = twinkle * 0.6 + 0.15

                context.fill(
                    Path(ellipseIn: CGRect(x: x - starSize/2, y: y - starSize/2, width: starSize, height: starSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.08),
                    Color(red: 0.05, green: 0.03, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                phase = .pi * 20
            }
        }
    }
}

struct CrescentGlowMotionView: View {
    let size: CGSize
    @State private var glowPhase: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.10),
                    Color(red: 0.05, green: 0.04, blue: 0.15),
                    Color(red: 0.02, green: 0.02, blue: 0.07),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.90, green: 0.80, blue: 0.50).opacity(0.12),
                            Color(red: 0.90, green: 0.80, blue: 0.50).opacity(0.04),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: size.width * 0.2, y: -size.height * 0.25)
                .scaleEffect(glowPhase ? 1.08 : 0.95)

            Image(systemName: "moon.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.88, blue: 0.60),
                            Color(red: 0.85, green: 0.75, blue: 0.45),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.90, green: 0.80, blue: 0.50).opacity(0.3), radius: 30)
                .offset(x: size.width * 0.2, y: -size.height * 0.25)
                .opacity(glowPhase ? 0.9 : 0.7)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
        }
    }
}

struct FloatingLanternsMotionView: View {
    let size: CGSize
    @State private var phase: Double = 0

    var body: some View {
        Canvas { context, canvasSize in
            let lanternCount = 15
            for i in 0..<lanternCount {
                let seed = Double(i) * 5.37
                let baseX = (sin(seed * 2.1) * 0.5 + 0.5) * canvasSize.width
                let baseY = (cos(seed * 1.7) * 0.5 + 0.5) * canvasSize.height
                let floatY = sin(phase * 0.15 + seed) * 8
                let floatX = cos(phase * 0.1 + seed * 0.7) * 4
                let lanternSize = (sin(seed) * 0.5 + 0.5) * 6 + 4
                let opacity = (sin(phase * 0.2 + seed * 1.3) * 0.3 + 0.5)

                let x = baseX + floatX
                let y = baseY + floatY

                let glowRect = CGRect(x: x - lanternSize * 2, y: y - lanternSize * 2, width: lanternSize * 4, height: lanternSize * 4)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(opacity * 0.08))
                )

                let rect = CGRect(x: x - lanternSize/2, y: y - lanternSize/2, width: lanternSize, height: lanternSize)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color(red: 0.95, green: 0.75, blue: 0.30).opacity(opacity * 0.6))
                )
            }
        }
        .frame(width: size.width, height: size.height)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.03, blue: 0.10),
                    Color(red: 0.06, green: 0.04, blue: 0.14),
                    Color(red: 0.03, green: 0.02, blue: 0.08),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
                phase = .pi * 20
            }
        }
    }
}

struct GentleCloudsMotionView: View {
    let size: CGSize
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.15),
                    Color(red: 0.03, green: 0.04, blue: 0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(Color.white.opacity(0.03))
                .frame(width: 400, height: 80)
                .blur(radius: 30)
                .offset(x: offset1 - 200, y: -size.height * 0.2)

            Ellipse()
                .fill(Color.white.opacity(0.025))
                .frame(width: 500, height: 100)
                .blur(radius: 40)
                .offset(x: offset2 - 250, y: -size.height * 0.05)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                offset1 = size.width + 400
            }
            withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) {
                offset2 = size.width + 500
            }
        }
    }
}

struct MosqueFogMotionView: View {
    let size: CGSize
    @State private var fogPhase: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.08),
                    Color(red: 0.06, green: 0.05, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.06),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i == 2 ? "building.columns.fill" : "building.fill")
                            .font(.system(size: CGFloat(30 + i * 5)))
                            .foregroundStyle(Color.white.opacity(0.06))
                    }
                }
                .offset(y: 20)
            }

            Ellipse()
                .fill(Color.white.opacity(fogPhase ? 0.04 : 0.02))
                .frame(width: size.width * 1.5, height: 200)
                .blur(radius: 50)
                .offset(y: size.height * 0.3)
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                fogPhase = true
            }
        }
    }
}
