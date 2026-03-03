import SwiftUI

struct FaceThumbnailView: View {
    let faceId: FaceId
    let theme: ThemeDefinition
    let isSelected: Bool

    var body: some View {
        ZStack {
            if theme.layers.gradientStops.count >= 2 {
                LinearGradient(
                    stops: theme.layers.gradientStops.map { Gradient.Stop(color: $0.color, location: $0.location) },
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                theme.palette.background
            }

            IslamicPatternView(
                pattern: theme.backgroundPattern,
                color: theme.palette.primary,
                scaleFactor: 0.2,
                opacity: theme.layers.patternOpacity * 0.7
            )

            skeletonLayout
        }
        .clipShape(.rect(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isSelected ? theme.palette.accent : .white.opacity(0.1),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .shadow(color: isSelected ? theme.palette.accent.opacity(0.3) : .black.opacity(0.2), radius: isSelected ? 12 : 6, y: 4)
    }

    @ViewBuilder
    private var skeletonLayout: some View {
        switch faceId {
        case .classicSplit: classicSplitSkeleton
        case .archFrame: archFrameSkeleton
        case .minimalNoor: minimalNoorSkeleton
        case .ledBoard: ledBoardSkeleton
        case .smartGlass: smartGlassSkeleton
        case .ottomanGold: ottomanGoldSkeleton
        }
    }

    private var classicSplitSkeleton: some View {
        HStack(spacing: 6) {
            VStack(spacing: 4) {
                Spacer()
                skeletonClock(size: 16)
                skeletonBar(width: 40, height: 4)
                Spacer()
                skeletonCard(width: 50, height: 20)
                Spacer()
            }
            VStack(spacing: 3) {
                skeletonBar(width: .infinity, height: 4)
                ForEach(0..<5, id: \.self) { _ in
                    skeletonBar(width: .infinity, height: 3)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
    }

    private var archFrameSkeleton: some View {
        VStack(spacing: 4) {
            archDecoration
                .frame(height: 12)
            skeletonClock(size: 18)
            skeletonBar(width: 40, height: 3)
            skeletonCard(width: .infinity, height: 30)
            Spacer()
            skeletonBar(width: .infinity, height: 4)
        }
        .padding(8)
    }

    private var minimalNoorSkeleton: some View {
        VStack(spacing: 4) {
            Spacer()
            skeletonClock(size: 22)
            skeletonBar(width: 50, height: 3)
            Spacer()
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(spacing: 2) {
                        skeletonBar(width: .infinity, height: 2)
                        skeletonBar(width: .infinity, height: 3)
                    }
                }
            }
            skeletonBar(width: .infinity, height: 4)
        }
        .padding(8)
    }

    private var ledBoardSkeleton: some View {
        VStack(spacing: 2) {
            HStack {
                skeletonClock(size: 12)
                Spacer()
                skeletonBar(width: 30, height: 3)
            }
            skeletonDivider
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 4) {
                    skeletonDot
                    skeletonBar(width: 20, height: 2)
                    Spacer()
                    skeletonBar(width: 16, height: 2)
                }
            }
            Spacer()
            skeletonBar(width: .infinity, height: 4)
        }
        .padding(6)
    }

    private var smartGlassSkeleton: some View {
        HStack(spacing: 5) {
            VStack(spacing: 5) {
                skeletonGlassCard {
                    VStack(spacing: 3) {
                        skeletonClock(size: 12)
                        skeletonBar(width: 30, height: 2)
                    }
                }
                skeletonGlassCard {
                    skeletonBar(width: 40, height: 10)
                }
                Spacer()
            }
            VStack(spacing: 3) {
                skeletonGlassCard {
                    VStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            skeletonBar(width: .infinity, height: 2)
                        }
                    }
                }
                Spacer()
                skeletonBar(width: .infinity, height: 3)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(8)
    }

    private var ottomanGoldSkeleton: some View {
        VStack(spacing: 3) {
            ornamentLine
            skeletonClock(size: 18)
            skeletonBar(width: 40, height: 3)
            ornamentLine
            skeletonCard(width: .infinity, height: 28)
            Spacer()
            skeletonBar(width: .infinity, height: 4)
            ornamentLine
        }
        .padding(8)
    }

    // MARK: - Skeleton Primitives

    private func skeletonClock(size: CGFloat) -> some View {
        Text("12:30")
            .font(.system(size: size, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
            .foregroundStyle(theme.palette.textPrimary)
            .monospacedDigit()
    }

    private func skeletonBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(theme.palette.textPrimary.opacity(0.15))
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
    }

    private func skeletonCard(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(theme.palette.surface.opacity(0.3))
            .frame(maxWidth: width == .infinity ? .infinity : width, minHeight: height, maxHeight: height)
    }

    private func skeletonGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(5)
            .background(theme.palette.surface.opacity(0.25))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(theme.palette.textPrimary.opacity(0.08), lineWidth: 0.5)
            )
    }

    private var skeletonDot: some View {
        Circle()
            .fill(theme.palette.primary.opacity(0.4))
            .frame(width: 4, height: 4)
    }

    private var skeletonDivider: some View {
        Rectangle()
            .fill(theme.palette.primary.opacity(0.15))
            .frame(height: 0.5)
    }

    private var archDecoration: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: w * 0.15, y: h))
                path.addQuadCurve(
                    to: CGPoint(x: w * 0.85, y: h),
                    control: CGPoint(x: w / 2, y: -h * 0.4)
                )
            }
            .stroke(theme.palette.accent.opacity(0.3), lineWidth: 1)
        }
    }

    private var ornamentLine: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, theme.palette.accent.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
            Circle()
                .fill(theme.palette.accent.opacity(0.4))
                .frame(width: 3, height: 3)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, theme.palette.accent.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
        }
    }
}
