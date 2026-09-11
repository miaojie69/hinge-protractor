import Foundation
import Observation

@Observable
final class HingeAngleModel {
    enum Unit: String, CaseIterable, Identifiable {
        case degrees, radians
        var id: Self { self }
        var symbol: String { self == .degrees ? "°" : " rad" }
    }

    enum SourceState: Equatable {
        case demoNoHinge, closed, partiallyOpen, fullyOpen, hardware
        var label: String {
            switch self {
            case .demoNoHinge: "演示模式 · 当前设备没有铰链"
            case .closed: "已闭合"
            case .partiallyOpen: "半开 · 硬件铰链"
            case .fullyOpen: "完全展开"
            case .hardware: "硬件铰链"
            }
        }
        var usesHardware: Bool { self != .demoNoHinge }
    }

    private(set) var liveDegrees = 0.0
    private(set) var frozenDegrees: Double?
    private(set) var zeroDegrees: Double?
    private(set) var sourceState: SourceState = .demoNoHinge
    var unit: Unit = .degrees

    var isFrozen: Bool { frozenDegrees != nil }
    var shownDegrees: Double { frozenDegrees ?? liveDegrees }
    var relativeDegrees: Double { shownDegrees - (zeroDegrees ?? 0) }
    var hasZero: Bool { zeroDegrees != nil }
    var hasHardwareHinge: Bool { sourceState.usesHardware }

    func receiveDemo(degrees: Double) {
        sourceState = .demoNoHinge
        liveDegrees = degrees.clamped(to: 0...180)
    }

    func receiveHardware(rawDegrees: Double, state: SourceState) {
        sourceState = state
        liveDegrees = normalizeHardwareDegrees(rawDegrees)
    }

    /// Converts Apple's raw coordinate to closed ≈ 0°, fully open ≈ 180°.
    /// The shipping Duo's zero point is not verified yet. If fully open is 0°,
    /// change only this function to return `180 - rawDegrees`.
    func normalizeHardwareDegrees(_ rawDegrees: Double) -> Double {
        rawDegrees.clamped(to: 0...180)
    }

    func reportNoHinge() { sourceState = .demoNoHinge }
    func toggleFreeze() { frozenDegrees = isFrozen ? nil : liveDegrees }
    func setZero() { zeroDegrees = shownDegrees }
    func clearZero() { zeroDegrees = nil }

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

