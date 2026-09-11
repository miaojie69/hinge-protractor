import SwiftUI

struct HingeArcView: View {
    let degrees: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.82)
            let radius = min(size.width * 0.42, size.height * 0.68)
            let clamped = min(max(degrees, 0), 180)
            let start = Angle.degrees(180)
            let end = Angle.degrees(180 + clamped)

            var sector = Path()
            sector.move(to: center)
            sector.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
            sector.closeSubpath()
            context.fill(sector, with: .color(.blue.opacity(0.2)))

            var arc = Path()
            arc.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
            context.stroke(arc, with: .color(.blue), lineWidth: 3)
            context.stroke(arm(center, radius, start), with: .color(.white), lineWidth: 5)
            context.stroke(arm(center, radius, end), with: .color(.white), lineWidth: 5)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(.blue))
        }
        .accessibilityHidden(true)
    }

    private func arm(_ center: CGPoint, _ radius: Double, _ angle: Angle) -> Path {
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + radius * cos(angle.radians), y: center.y + radius * sin(angle.radians)))
        return path
    }
}

