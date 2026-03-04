import SwiftUI

struct IslamicPatternView: View, Equatable {
    let pattern: BackgroundPattern
    let color: Color
    let scaleFactor: CGFloat
    var opacity: CGFloat = 0.08

    nonisolated static func == (lhs: IslamicPatternView, rhs: IslamicPatternView) -> Bool {
        lhs.pattern == rhs.pattern && lhs.scaleFactor == rhs.scaleFactor && lhs.opacity == rhs.opacity
    }

    var body: some View {
        Canvas { context, size in
            guard pattern != .none else { return }
            switch pattern {
            case .geometricStars:
                drawGeometricStars(context: context, size: size)
            case .arabesque:
                drawArabesque(context: context, size: size)
            case .minimal:
                drawMinimal(context: context, size: size)
            case .reliefStarfield:
                drawReliefStarfield(context: context, size: size)
            case .archMosaic:
                drawArchMosaic(context: context, size: size)
            case .hexGrid:
                drawHexGrid(context: context, size: size)
            case .glassTile:
                drawGlassTile(context: context, size: size)
            case .ledMatrix:
                drawLEDMatrix(context: context, size: size)
            case .mosqueSilhouette:
                drawMosqueSilhouette(context: context, size: size)
            case .none:
                break
            }
        }
        .drawingGroup(opaque: false, colorMode: .linear)
        .opacity(opacity)
    }

    // MARK: - Original Patterns

    private func drawGeometricStars(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 60 * scaleFactor
        let starSize: CGFloat = 12 * scaleFactor
        var y: CGFloat = 0
        var row = 0
        while y < size.height + spacing {
            var x: CGFloat = row % 2 == 0 ? 0 : spacing / 2
            while x < size.width + spacing {
                drawStar(context: context, center: CGPoint(x: x, y: y), size: starSize, points: 8)
                x += spacing
            }
            y += spacing
            row += 1
        }
    }

    private func drawStar(context: GraphicsContext, center: CGPoint, size: CGFloat, points: Int) {
        var path = Path()
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? size : size * 0.4
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        context.stroke(path, with: .color(color), lineWidth: 1)
    }

    private func drawArabesque(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 80 * scaleFactor
        var y: CGFloat = 0
        while y < size.height + spacing {
            var x: CGFloat = 0
            while x < size.width + spacing {
                drawOrnament(context: context, center: CGPoint(x: x, y: y), size: 20 * scaleFactor)
                x += spacing
            }
            y += spacing
        }
    }

    private func drawOrnament(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - size/2, y: center.y - size/4, width: size, height: size/2))
        path.addEllipse(in: CGRect(x: center.x - size/4, y: center.y - size/2, width: size/2, height: size))
        context.stroke(path, with: .color(color), lineWidth: 0.8)
    }

    private func drawMinimal(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 100 * scaleFactor
        var y: CGFloat = 0
        while y < size.height + spacing {
            var x: CGFloat = 0
            while x < size.width + spacing {
                var path = Path()
                path.addArc(center: CGPoint(x: x, y: y), radius: 4 * scaleFactor, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                context.fill(path, with: .color(color))
                x += spacing
            }
            y += spacing
        }
    }

    // MARK: - Relief Starfield — dual-scale rosettes with carved depth

    private func drawReliefStarfield(context: GraphicsContext, size: CGSize) {
        let largeSpacing: CGFloat = 140 * scaleFactor
        let smallSpacing: CGFloat = 70 * scaleFactor
        let largeR: CGFloat = 28 * scaleFactor
        let smallR: CGFloat = 10 * scaleFactor

        var y: CGFloat = -largeSpacing / 2
        var row = 0
        while y < size.height + largeSpacing {
            var x: CGFloat = row % 2 == 0 ? 0 : largeSpacing / 2
            while x < size.width + largeSpacing {
                let center = CGPoint(x: x, y: y)

                var shadowCtx = context
                shadowCtx.translateBy(x: 1.5 * scaleFactor, y: 1.5 * scaleFactor)
                drawRosette(context: shadowCtx, center: center, radius: largeR, petals: 12, alpha: 0.06)

                var highlightCtx = context
                highlightCtx.translateBy(x: -0.8 * scaleFactor, y: -0.8 * scaleFactor)
                drawRosette(context: highlightCtx, center: center, radius: largeR, petals: 12, alpha: 0.03)

                drawRosette(context: context, center: center, radius: largeR, petals: 12, alpha: 1.0)
                drawRosette(context: context, center: center, radius: largeR * 0.45, petals: 8, alpha: 0.5)

                var dot = Path()
                dot.addArc(center: center, radius: 3 * scaleFactor, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                context.fill(dot, with: .color(color.opacity(0.4)))

                x += largeSpacing
            }
            y += largeSpacing
            row += 1
        }

        var sy: CGFloat = smallSpacing / 2
        var srow = 0
        while sy < size.height + smallSpacing {
            var sx: CGFloat = srow % 2 == 0 ? smallSpacing / 4 : smallSpacing * 3 / 4
            while sx < size.width + smallSpacing {
                let sCenter = CGPoint(x: sx, y: sy)
                drawMicroRosette(context: context, center: sCenter, radius: smallR, petals: 6, alpha: 0.2)
                sx += smallSpacing
            }
            sy += smallSpacing
            srow += 1
        }

        let connSpacing: CGFloat = largeSpacing
        var cy: CGFloat = 0
        while cy < size.height + connSpacing {
            var cx: CGFloat = 0
            while cx < size.width + connSpacing {
                var line = Path()
                line.move(to: CGPoint(x: cx - largeR * 0.7, y: cy))
                line.addLine(to: CGPoint(x: cx + largeR * 0.7, y: cy))
                context.stroke(line, with: .color(color.opacity(0.08)), lineWidth: 0.5 * scaleFactor)
                cx += connSpacing
            }
            cy += connSpacing
        }
    }

    private func drawRosette(context: GraphicsContext, center: CGPoint, radius: CGFloat, petals: Int, alpha: CGFloat) {
        var path = Path()
        for i in 0..<petals {
            let angle = Double(i) * (2 * .pi / Double(petals))
            let tipX = center.x + CGFloat(cos(angle)) * radius
            let tipY = center.y + CGFloat(sin(angle)) * radius
            let cAngle1 = angle - 0.3
            let cAngle2 = angle + 0.3
            let cr: CGFloat = radius * 0.55
            let cp2 = CGPoint(x: center.x + CGFloat(cos(cAngle2)) * cr, y: center.y + CGFloat(sin(cAngle2)) * cr)
            if i == 0 { path.move(to: CGPoint(x: tipX, y: tipY)) }
            let nextAngle = Double(i + 1) * (2 * .pi / Double(petals))
            let nextTip = CGPoint(x: center.x + CGFloat(cos(nextAngle)) * radius, y: center.y + CGFloat(sin(nextAngle)) * radius)
            let nextCp1 = CGPoint(x: center.x + CGFloat(cos(nextAngle - 0.3)) * cr, y: center.y + CGFloat(sin(nextAngle - 0.3)) * cr)
            path.addCurve(to: nextTip, control1: cp2, control2: nextCp1)
            _ = cAngle1
        }
        path.closeSubpath()
        context.stroke(path, with: .color(color.opacity(alpha)), lineWidth: 1.2 * scaleFactor)
    }

    private func drawMicroRosette(context: GraphicsContext, center: CGPoint, radius: CGFloat, petals: Int, alpha: CGFloat) {
        var path = Path()
        for i in 0..<petals {
            let angle = Double(i) * (2 * .pi / Double(petals))
            let tip = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: tip) }
            let nextAngle = Double(i + 1) * (2 * .pi / Double(petals))
            let nextTip = CGPoint(x: center.x + CGFloat(cos(nextAngle)) * radius, y: center.y + CGFloat(sin(nextAngle)) * radius)
            let midAngle = (angle + nextAngle) / 2
            let midR = radius * 0.35
            let cp = CGPoint(x: center.x + CGFloat(cos(midAngle)) * midR, y: center.y + CGFloat(sin(midAngle)) * midR)
            path.addQuadCurve(to: nextTip, control: cp)
        }
        path.closeSubpath()
        context.stroke(path, with: .color(color.opacity(alpha)), lineWidth: 0.8 * scaleFactor)
    }

    // MARK: - Arch Mosaic — concentric arches with 6-point star bands

    private func drawArchMosaic(context: GraphicsContext, size: CGSize) {
        let archSpacing: CGFloat = 140 * scaleFactor
        let archCount = Int(size.width / archSpacing) + 2
        for i in 0..<archCount {
            let baseX = CGFloat(i) * archSpacing + archSpacing / 2
            let archHeight = size.height * 0.85
            let archWidth = archSpacing * 0.75

            for band in 0..<4 {
                let inset = CGFloat(band) * archWidth * 0.1
                var path = Path()
                let left = CGPoint(x: baseX - archWidth / 2 + inset, y: size.height)
                let right = CGPoint(x: baseX + archWidth / 2 - inset, y: size.height)
                path.move(to: left)
                let cp1 = CGPoint(x: left.x, y: size.height - archHeight + inset * 2.5)
                let cp2 = CGPoint(x: right.x, y: size.height - archHeight + inset * 2.5)
                path.addCurve(to: right, control1: cp1, control2: cp2)
                let alphaFactor = Double(4 - band) / 5.0
                context.stroke(path, with: .color(color.opacity(alphaFactor)), lineWidth: (2.0 - CGFloat(band) * 0.4) * scaleFactor)
            }

            let keystoneY = size.height - archHeight * 0.92
            drawStar(context: context, center: CGPoint(x: baseX, y: keystoneY), size: 8 * scaleFactor, points: 6)
        }

        let tileSpacing: CGFloat = 55 * scaleFactor
        var ty: CGFloat = 0
        var trow = 0
        while ty < size.height * 0.35 {
            var tx: CGFloat = trow % 2 == 0 ? 0 : tileSpacing / 2
            while tx < size.width + tileSpacing {
                drawStar(context: context, center: CGPoint(x: tx, y: ty), size: 5 * scaleFactor, points: 6)

                var ring = Path()
                ring.addArc(center: CGPoint(x: tx, y: ty), radius: 8 * scaleFactor, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                context.stroke(ring, with: .color(color.opacity(0.15)), lineWidth: 0.5 * scaleFactor)

                tx += tileSpacing
            }
            ty += tileSpacing
            trow += 1
        }

        for j in 0..<archCount {
            let x = CGFloat(j) * archSpacing + archSpacing / 2
            var line = Path()
            line.move(to: CGPoint(x: x, y: size.height * 0.4))
            line.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(line, with: .color(color.opacity(0.06)), lineWidth: 0.5 * scaleFactor)
        }
    }

    // MARK: - Hex Grid — 3D illusion hexagonal grid

    private func drawHexGrid(context: GraphicsContext, size: CGSize) {
        let hexR: CGFloat = 30 * scaleFactor
        let hexW = hexR * 1.5
        let hexH = hexR * sqrt(3)
        var row = 0
        var y: CGFloat = -hexH / 2
        while y < size.height + hexH {
            var x: CGFloat = row % 2 == 0 ? 0 : hexW
            while x < size.width + hexW * 2 {
                let center = CGPoint(x: x, y: y)
                drawHexagonWithDepth(context: context, center: center, radius: hexR)
                x += hexW * 2
            }
            y += hexH / 2
            row += 1
        }
    }

    private func drawHexagonWithDepth(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var outerPath = Path()
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3 - .pi / 6
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { outerPath.move(to: pt) } else { outerPath.addLine(to: pt) }
        }
        outerPath.closeSubpath()
        context.stroke(outerPath, with: .color(color), lineWidth: 1.0 * scaleFactor)

        let innerR = radius * 0.62
        var innerPath = Path()
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * innerR, y: center.y + CGFloat(sin(angle)) * innerR)
            if i == 0 { innerPath.move(to: pt) } else { innerPath.addLine(to: pt) }
        }
        innerPath.closeSubpath()
        context.stroke(innerPath, with: .color(color.opacity(0.35)), lineWidth: 0.8 * scaleFactor)

        for i in 0..<6 {
            let outerAngle = Double(i) * .pi / 3 - .pi / 6
            let innerAngle = Double(i) * .pi / 3
            let outerPt = CGPoint(x: center.x + CGFloat(cos(outerAngle)) * radius, y: center.y + CGFloat(sin(outerAngle)) * radius)
            let innerPt = CGPoint(x: center.x + CGFloat(cos(innerAngle)) * innerR, y: center.y + CGFloat(sin(innerAngle)) * innerR)
            var conn = Path()
            conn.move(to: outerPt)
            conn.addLine(to: innerPt)
            context.stroke(conn, with: .color(color.opacity(0.2)), lineWidth: 0.6 * scaleFactor)
        }

        let topFaces = [0, 1, 5]
        for i in topFaces {
            let a1 = Double(i) * .pi / 3 - .pi / 6
            let a2 = Double((i + 1) % 6) * .pi / 3 - .pi / 6
            let ia = Double(i) * .pi / 3
            let outerP1 = CGPoint(x: center.x + CGFloat(cos(a1)) * radius, y: center.y + CGFloat(sin(a1)) * radius)
            let outerP2 = CGPoint(x: center.x + CGFloat(cos(a2)) * radius, y: center.y + CGFloat(sin(a2)) * radius)
            let innerP = CGPoint(x: center.x + CGFloat(cos(ia)) * innerR, y: center.y + CGFloat(sin(ia)) * innerR)
            var face = Path()
            face.move(to: outerP1)
            face.addLine(to: outerP2)
            face.addLine(to: innerP)
            face.closeSubpath()
            context.fill(face, with: .color(color.opacity(0.04)))
        }
    }

    // MARK: - Glass Tile — frosted diamond lattice with scan-lines

    private func drawGlassTile(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 75 * scaleFactor

        var y: CGFloat = -spacing
        var row = 0
        while y < size.height + spacing * 2 {
            var x: CGFloat = row % 2 == 0 ? 0 : spacing / 2
            while x < size.width + spacing {
                let center = CGPoint(x: x, y: y)
                drawFrostedDiamond(context: context, center: center, size: spacing * 0.32)
                x += spacing
            }
            y += spacing * 0.65
            row += 1
        }

        var lx: CGFloat = 0
        while lx < size.width + spacing {
            var diagLine = Path()
            diagLine.move(to: CGPoint(x: lx, y: 0))
            diagLine.addLine(to: CGPoint(x: lx - size.height * 0.4, y: size.height))
            context.stroke(diagLine, with: .color(color.opacity(0.04)), lineWidth: 0.4 * scaleFactor)
            lx += spacing * 1.2
        }

        let scanSpacing: CGFloat = 4 * scaleFactor
        var scanY: CGFloat = 0
        while scanY < size.height {
            var scanLine = Path()
            scanLine.move(to: CGPoint(x: 0, y: scanY))
            scanLine.addLine(to: CGPoint(x: size.width, y: scanY))
            context.stroke(scanLine, with: .color(color.opacity(0.02)), lineWidth: 0.5 * scaleFactor)
            scanY += scanSpacing
        }
    }

    private func drawFrostedDiamond(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - size))
        path.addLine(to: CGPoint(x: center.x + size * 0.7, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        path.addLine(to: CGPoint(x: center.x - size * 0.7, y: center.y))
        path.closeSubpath()
        context.fill(path, with: .color(color.opacity(0.025)))
        context.stroke(path, with: .color(color), lineWidth: 0.8 * scaleFactor)

        let inR = size * 0.4
        var inner = Path()
        inner.move(to: CGPoint(x: center.x, y: center.y - inR))
        inner.addLine(to: CGPoint(x: center.x + inR * 0.7, y: center.y))
        inner.addLine(to: CGPoint(x: center.x, y: center.y + inR))
        inner.addLine(to: CGPoint(x: center.x - inR * 0.7, y: center.y))
        inner.closeSubpath()
        context.stroke(inner, with: .color(color.opacity(0.3)), lineWidth: 0.5 * scaleFactor)
    }

    // MARK: - LED Matrix — dot grid with subtle glow

    private func drawLEDMatrix(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 18 * scaleFactor
        let dotR: CGFloat = 1.2 * scaleFactor
        let glowR: CGFloat = 3.0 * scaleFactor

        var y: CGFloat = spacing / 2
        var row = 0
        while y < size.height {
            var x: CGFloat = spacing / 2
            var col = 0
            while x < size.width {
                let isAccent = (row % 8 == 0 || col % 12 == 0)
                let dotAlpha: CGFloat = isAccent ? 0.5 : 0.22

                if isAccent {
                    var glow = Path()
                    glow.addArc(center: CGPoint(x: x, y: y), radius: glowR, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                    context.fill(glow, with: .color(color.opacity(0.06)))
                }

                var dot = Path()
                dot.addArc(center: CGPoint(x: x, y: y), radius: dotR, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                context.fill(dot, with: .color(color.opacity(dotAlpha)))

                x += spacing
                col += 1
            }
            y += spacing
            row += 1
        }

        let gridLineSpacing: CGFloat = spacing * 8
        var gx: CGFloat = gridLineSpacing
        while gx < size.width {
            var vline = Path()
            vline.move(to: CGPoint(x: gx, y: 0))
            vline.addLine(to: CGPoint(x: gx, y: size.height))
            context.stroke(vline, with: .color(color.opacity(0.03)), lineWidth: 0.4 * scaleFactor)
            gx += gridLineSpacing
        }
        var gy: CGFloat = gridLineSpacing
        while gy < size.height {
            var hline = Path()
            hline.move(to: CGPoint(x: 0, y: gy))
            hline.addLine(to: CGPoint(x: size.width, y: gy))
            context.stroke(hline, with: .color(color.opacity(0.03)), lineWidth: 0.4 * scaleFactor)
            gy += gridLineSpacing
        }
    }

    // MARK: - Mosque Silhouette — stylized skyline with starfield

    private func drawMosqueSilhouette(context: GraphicsContext, size: CGSize) {
        let baseY = size.height * 0.72

        var silhouette = Path()
        silhouette.move(to: CGPoint(x: 0, y: size.height))
        silhouette.addLine(to: CGPoint(x: 0, y: baseY))

        let segments: [(dx: CGFloat, type: String)] = [
            (0.06, "flat"), (0.08, "minaret"), (0.04, "flat"),
            (0.16, "dome"), (0.03, "flat"), (0.06, "minaret"),
            (0.04, "flat"), (0.14, "dome"), (0.03, "flat"),
            (0.06, "minaret"), (0.04, "flat"), (0.12, "dome"),
            (0.03, "flat"), (0.07, "minaret"), (0.04, "flat"),
        ]

        var cx: CGFloat = 0
        for seg in segments {
            let segW = size.width * seg.dx
            let startX = cx
            let endX = cx + segW

            switch seg.type {
            case "minaret":
                let mW = segW * 0.35
                let mH = size.height * 0.20
                let mX = startX + segW / 2
                silhouette.addLine(to: CGPoint(x: mX - mW / 2, y: baseY))
                silhouette.addLine(to: CGPoint(x: mX - mW / 3, y: baseY - mH * 0.8))
                silhouette.addLine(to: CGPoint(x: mX - mW / 6, y: baseY - mH * 0.92))
                silhouette.addLine(to: CGPoint(x: mX, y: baseY - mH))
                silhouette.addLine(to: CGPoint(x: mX + mW / 6, y: baseY - mH * 0.92))
                silhouette.addLine(to: CGPoint(x: mX + mW / 3, y: baseY - mH * 0.8))
                silhouette.addLine(to: CGPoint(x: mX + mW / 2, y: baseY))
                silhouette.addLine(to: CGPoint(x: endX, y: baseY))
            case "dome":
                silhouette.addLine(to: CGPoint(x: startX, y: baseY))
                let domeH = size.height * 0.14
                let peak = CGPoint(x: startX + segW / 2, y: baseY - domeH)
                let cp1 = CGPoint(x: startX + segW * 0.1, y: baseY - domeH * 0.9)
                let cp2 = CGPoint(x: startX + segW * 0.35, y: baseY - domeH * 1.1)
                let cp3 = CGPoint(x: endX - segW * 0.35, y: baseY - domeH * 1.1)
                let cp4 = CGPoint(x: endX - segW * 0.1, y: baseY - domeH * 0.9)
                silhouette.addCurve(to: peak, control1: cp1, control2: cp2)
                silhouette.addCurve(to: CGPoint(x: endX, y: baseY), control1: cp3, control2: cp4)
            default:
                silhouette.addLine(to: CGPoint(x: endX, y: baseY + CGFloat.random(in: -2...2) * scaleFactor))
            }
            cx = endX
        }

        if cx < size.width {
            silhouette.addLine(to: CGPoint(x: size.width, y: baseY))
        }
        silhouette.addLine(to: CGPoint(x: size.width, y: size.height))
        silhouette.closeSubpath()
        context.fill(silhouette, with: .color(color))

        let starSpacing: CGFloat = 60 * scaleFactor
        var sy: CGFloat = starSpacing / 3
        var srow = 0
        while sy < baseY - 30 * scaleFactor {
            var sx: CGFloat = srow % 2 == 0 ? starSpacing / 2 : starSpacing / 4
            while sx < size.width {
                let dotSize: CGFloat = CGFloat.random(in: 1.0...2.2) * scaleFactor
                let dotAlpha = CGFloat.random(in: 0.08...0.3)
                var dot = Path()
                dot.addArc(center: CGPoint(x: sx, y: sy), radius: dotSize, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
                context.fill(dot, with: .color(color.opacity(dotAlpha)))
                sx += starSpacing
            }
            sy += starSpacing * 0.8
            srow += 1
        }

        let crescentX = size.width * 0.82
        let crescentY = baseY * 0.2
        let crescentR: CGFloat = 12 * scaleFactor
        var crescent = Path()
        crescent.addArc(center: CGPoint(x: crescentX, y: crescentY), radius: crescentR, startAngle: .degrees(-40), endAngle: .degrees(220), clockwise: false)
        crescent.addArc(center: CGPoint(x: crescentX + crescentR * 0.3, y: crescentY - crescentR * 0.1), radius: crescentR * 0.85, startAngle: .degrees(220), endAngle: .degrees(-40), clockwise: true)
        crescent.closeSubpath()
        context.fill(crescent, with: .color(color.opacity(0.4)))
    }
}
