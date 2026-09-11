import Foundation
import Observation

@Observable
final class MeasurementModel {
    enum Unit: String, CaseIterable, Identifiable {
        case degrees
        case radians

        var id: Self { self }
        var title: String { self == .degrees ? "Degrees" : "Radians" }
        var symbol: String { self == .degrees ? "°" : " rad" }
    }

    private(set) var liveDegrees = 0.0
    private(set) var frozenDegrees: Double?
    private(set) var zeroDegrees: Double?
    var unit: Unit = .degrees

    var isFrozen: Bool { frozenDegrees != nil }
    var shownDegrees: Double { frozenDegrees ?? liveDegrees }
    var relativeDegrees: Double { shownDegrees - (zeroDegrees ?? 0) }
    var hasZero: Bool { zeroDegrees != nil }

    func receive(degrees: Double) {
        liveDegrees = degrees.clamped(to: 0...180)
    }

    func toggleFreeze() {
        frozenDegrees = isFrozen ? nil : liveDegrees
    }

    func setZero() {
        zeroDegrees = shownDegrees
    }

    func clearZero() {
        zeroDegrees = nil
    }

    func formatted(_ degrees: Double, signed: Bool = false) -> String {
        let value = unit == .degrees ? degrees : degrees * .pi / 180
        let format = unit == .degrees ? "%.1f" : "%.3f"
        let number = String(format: signed && value > 0 ? "+\(format)" : format, value)
        return number + unit.symbol
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
