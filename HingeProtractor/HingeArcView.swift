import SwiftUI

/// The instrument face: an engraved 0–180° scale with the measured angle drawn
/// as two arms from a vertex.
///
/// On iPhone Duo the vertex is placed on the fold, so the two arms lie along
/// the two physical halves of the device and the drawing coincides 1:1 with the
/// hardware it is drawn on. `vertex` is a unit position so the caller can put it
/// on the crease; the default sits it low and centred for a single screen.
struct HingeArcView: View {
    let degrees: Double
    var vertex = UnitPoint(x: 0.5, y: 0.86)
    var showsNumerals = true

    private static let majorStep = 30.0
    private static let mediumStep = 10.0
    private static let minorStep = 2.0

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * vertex.x, y: size.height * vertex.y)
            // Leaves room for the numerals engraved outside the rim.
            let radius = min(size.width * 0.40, size.height * 0.72)
            guard radius > 20 else { return }
            let value = min(max(degrees, 0), 180)

            engraveScale(in: &context, origin: origin, radius: radius)
            drawSweep(in: &context, origin: origin, radius: radius, value: value)
            drawArms(in: &context, origin: origin, radius: radius, value: value)
            drawHub(in: &context, origin: origin)
        }
        .accessibilityHidden(true)
    }

    private func point(_ origin: CGPoint, _ radius: Double, _ reading: Double) -> CGPoint {
        let radians = (180 + reading) * .pi / 180
        return CGPoint(x: origin.x + radius * cos(radians), y: origin.y + radius * sin(radians))
    }

    private func engraveScale(in context: inout GraphicsContext, origin: CGPoint, radius: Double) {
        var minor = Path(), medium = Path(), major = Path()
        for step in stride(from: 0.0, through: 180.0, by: Self.minorStep) {
            let isMajor = step.truncatingRemainder(dividingBy: Self.majorStep) == 0
            let isMedium = step.truncatingRemainder(dividingBy: Self.mediumStep) == 0
            let length = isMajor ? 14.0 : (isMedium ? 9.0 : 4.5)
            let outer = point(origin, radius, step)
            let inner = point(origin, radius - length, step)
            if isMajor { major.move(to: inner); major.addLine(to: outer) }
            else if isMedium { medium.move(to: inner); medium.addLine(to: outer) }
            else { minor.move(to: inner); minor.addLine(to: outer) }
        }
        context.stroke(minor, with: .color(InstrumentTheme.engravingFaint), lineWidth: 1)
        context.stroke(medium, with: .color(InstrumentTheme.engraving), lineWidth: 1)
        context.stroke(major, with: .color(InstrumentTheme.engravingBright), lineWidth: 1.5)

        var rim = Path()
        rim.addArc(center: origin, radius: radius, startAngle: .degrees(180),
                   endAngle: .degrees(360), clockwise: false)
        context.stroke(rim, with: .color(InstrumentTheme.engraving), lineWidth: 1)

        guard showsNumerals else { return }
        // Outside the rim, where the moving arm cannot cross them.
        for step in stride(from: 0.0, through: 180.0, by: Self.majorStep) {
            let position = point(origin, radius + 15, step)
            let numeral = Text("\(Int(step))")
                .font(.system(size: 10, weight: .regular).monospacedDigit())
                .foregroundStyle(InstrumentTheme.textFaint)
            context.draw(numeral, at: position)
        }
    }

    private func drawSweep(in context: inout GraphicsContext, origin: CGPoint, radius: Double, value: Double) {
        var sector = Path()
        sector.move(to: origin)
        sector.addArc(center: origin, radius: radius - 16, startAngle: .degrees(180),
                      endAngle: .degrees(180 + value), clockwise: false)
        sector.closeSubpath()
        context.fill(sector, with: .color(InstrumentTheme.accent.opacity(0.055)))
    }

    private func drawArms(in context: inout GraphicsContext, origin: CGPoint, radius: Double, value: Double) {
        // Reference arm: the half of the device that is held still.
        var reference = Path()
        reference.move(to: origin)
        reference.addLine(to: point(origin, radius - 16, 0))
        context.stroke(reference, with: .color(InstrumentTheme.textFaint), lineWidth: 2)

        var measured = Path()
        measured.move(to: origin)
        measured.addLine(to: point(origin, radius - 16, value))
        context.stroke(measured, with: .color(InstrumentTheme.accent), lineWidth: 2.5)

        // Index mark riding the scale at the current reading.
        var index = Path()
        index.move(to: point(origin, radius - 16, value))
        index.addLine(to: point(origin, radius + 5, value))
        context.stroke(index, with: .color(InstrumentTheme.accentBright), lineWidth: 2)
    }

    private func drawHub(in context: inout GraphicsContext, origin: CGPoint) {
        let outer = CGRect(x: origin.x - 5, y: origin.y - 5, width: 10, height: 10)
        context.stroke(Path(ellipseIn: outer), with: .color(InstrumentTheme.accent), lineWidth: 1.5)
        let inner = CGRect(x: origin.x - 1.5, y: origin.y - 1.5, width: 3, height: 3)
        context.fill(Path(ellipseIn: inner), with: .color(InstrumentTheme.accentBright))
    }
}
