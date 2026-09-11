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
        /// Hardware path compiled out: the slider is the only input.
        case demo
        /// Hardware path compiled in, but no callback has arrived yet.
        case awaitingHardware
        /// Hardware path reported that this device has no hinge.
        case noHinge
        case closed, partiallyOpen, fullyOpen, hardwareUnknown

        var label: String {
            switch self {
            case .demo: "演示模式 · 模拟角度 · 非实测"
            case .awaitingHardware: "等待硬件信息…"
            case .noHinge: "本机无铰链 · 演示模式"
            case .closed: "已闭合 · 硬件铰链"
            case .partiallyOpen: "半开 · 硬件铰链"
            case .fullyOpen: "完全展开 · 硬件铰链"
            case .hardwareUnknown: "硬件铰链"
            }
        }

        var usesHardware: Bool {
            switch self {
            case .closed, .partiallyOpen, .fullyOpen, .hardwareUnknown: true
            case .demo, .awaitingHardware, .noHinge: false
            }
        }
    }

    private(set) var liveDegrees = 0.0
    private(set) var frozenDegrees: Double?
    private(set) var zeroDegrees: Double?
    private(set) var sourceState: SourceState
    /// Kept unconverted for future calibration work; never drives the UI.
    private(set) var lastRawHardwareDegrees: Double?
    var unit: Unit = .degrees

    init() {
#if DUO_SDK_AVAILABLE
        sourceState = .awaitingHardware
#else
        sourceState = .demo
#endif
    }

    var isFrozen: Bool { frozenDegrees != nil }
    var shownDegrees: Double { frozenDegrees ?? liveDegrees }
    var relativeDegrees: Double { shownDegrees - (zeroDegrees ?? 0) }
    var hasZero: Bool { zeroDegrees != nil }
    var hasHardwareHinge: Bool { sourceState.usesHardware }
    /// The slider may only drive the model while no hardware hinge is reporting.
    var acceptsDemoInput: Bool { !hasHardwareHinge }

    func receiveDemo(degrees: Double) {
        guard acceptsDemoInput, degrees.isFinite else { return }
        liveDegrees = degrees.clamped(to: 0...180)
    }

    func receiveHardware(rawDegrees: Double, state: SourceState) {
        guard rawDegrees.isFinite else { return }
        sourceState = state
        lastRawHardwareDegrees = rawDegrees
        liveDegrees = normalizeHardwareDegrees(rawDegrees)
    }

    /// The single place raw hardware coordinates become closed ≈ 0°,
    /// fully open ≈ 180°. The real coordinate system is unverified; if fully
    /// open turns out to be 0°, change only this function to `180 - rawDegrees`.
    func normalizeHardwareDegrees(_ rawDegrees: Double) -> Double {
        guard rawDegrees.isFinite else { return 0 }
        return rawDegrees.clamped(to: 0...180)
    }

    func reportNoHinge() {
        sourceState = .noHinge
        lastRawHardwareDegrees = nil
    }

    func toggleFreeze() { frozenDegrees = isFrozen ? nil : liveDegrees }
    /// Uses the displayed value, so zeroing while frozen records the frozen
    /// reading rather than whatever input has arrived since.
    func setZero() { zeroDegrees = shownDegrees }
    func clearZero() { zeroDegrees = nil }

    func formatted(_ degrees: Double, signed: Bool = false) -> String {
        guard degrees.isFinite else { return "--" + unit.symbol }
        let converted = unit == .degrees ? degrees : degrees * .pi / 180
        let value = converted == 0 ? 0 : converted
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
