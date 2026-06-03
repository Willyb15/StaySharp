import SwiftUI

struct TunerMeterView: View {
    let cents: Float
    let state: Note.TuningState

    @State private var animatedCents: Float = 0

    private let arcRadius: CGFloat = 130
    private let needleLength: CGFloat = 120

    private func centsToAngle(_ cents: Double) -> Double {
        Double.pi * (1.0 + (cents + 50.0) / 100.0)
    }

    private var needleAngle: Double { centsToAngle(Double(animatedCents)) }

    private var needleColor: Color {
        switch state {
        case .inTune: return .green
        case .flat:   return Color(hue: 0.6, saturation: 0.9, brightness: 1.0)
        case .sharp:  return Color(hue: 0.08, saturation: 0.9, brightness: 1.0)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height - 8)
            Canvas { ctx, _ in
                drawArcTrack(ctx: ctx, center: center)
                drawTickMarks(ctx: ctx, center: center)
                drawCentLabels(ctx: ctx, center: center)
                drawNeedle(ctx: ctx, center: center)
                drawNeedlePivot(ctx: ctx, center: center)
            }
        }
        .frame(height: arcRadius + 44)
        .onChange(of: cents) { _, newVal in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.65)) {
                animatedCents = newVal
            }
        }
        .onAppear { animatedCents = cents }
    }

    private func drawArcTrack(ctx: GraphicsContext, center: CGPoint) {
        var path = Path()
        let steps = 120
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let angle = Double.pi + t * Double.pi
            let x = center.x + arcRadius * cos(angle)
            let y = center.y + arcRadius * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        ctx.stroke(path, with: .color(.white.opacity(0.15)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        var inTunePath = Path()
        let inTuneStart = centsToAngle(-5)
        let inTuneEnd = centsToAngle(5)
        for i in 0...20 {
            let t = Double(i) / 20.0
            let angle = inTuneStart + t * (inTuneEnd - inTuneStart)
            let x = center.x + arcRadius * cos(angle)
            let y = center.y + arcRadius * sin(angle)
            if i == 0 { inTunePath.move(to: CGPoint(x: x, y: y)) }
            else { inTunePath.addLine(to: CGPoint(x: x, y: y)) }
        }
        ctx.stroke(inTunePath, with: .color(.green.opacity(0.4)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    }

    private func drawTickMarks(ctx: GraphicsContext, center: CGPoint) {
        let ticks: [(cents: Double, length: CGFloat)] = [
            (-50, 12), (-25, 8), (0, 16), (25, 8), (50, 12),
            (-40, 5), (-30, 5), (-20, 5), (-10, 5),
            (10, 5), (20, 5), (30, 5), (40, 5),
        ]
        for tick in ticks {
            let angle = centsToAngle(tick.cents)
            let inner = arcRadius - tick.length
            let outer = arcRadius + 2
            var path = Path()
            path.move(to: CGPoint(x: center.x + inner * cos(angle), y: center.y + inner * sin(angle)))
            path.addLine(to: CGPoint(x: center.x + outer * cos(angle), y: center.y + outer * sin(angle)))
            let color: Color = tick.cents == 0 ? .white.opacity(0.8) : .white.opacity(0.4)
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: tick.length >= 12 ? 2 : 1.5, lineCap: .round))
        }
    }

    private func drawCentLabels(ctx: GraphicsContext, center: CGPoint) {
        let items: [(Double, String)] = [(-20, "−20"), (-10, "−10"), (0, "0"), (10, "+10"), (20, "+20")]
        let r = arcRadius + 16
        for (c, label) in items {
            let angle = centsToAngle(c)
            let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            let t = ctx.resolve(
                Text(label)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(c == 0 ? .white.opacity(0.55) : .white.opacity(0.3))
            )
            ctx.draw(t, at: pt)
        }
    }

    private func drawNeedle(ctx: GraphicsContext, center: CGPoint) {
        let tipX = center.x + needleLength * cos(needleAngle)
        let tipY = center.y + needleLength * sin(needleAngle)
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(x: tipX, y: tipY))
        ctx.stroke(path, with: .color(needleColor), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        ctx.fill(
            Path(ellipseIn: CGRect(x: tipX - 4, y: tipY - 4, width: 8, height: 8)),
            with: .color(needleColor)
        )
    }

    private func drawNeedlePivot(ctx: GraphicsContext, center: CGPoint) {
        ctx.fill(
            Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)),
            with: .color(.white.opacity(0.8))
        )
    }
}

#Preview {
    ZStack {
        Color.black
        TunerMeterView(cents: -20, state: .flat).padding()
    }
}
