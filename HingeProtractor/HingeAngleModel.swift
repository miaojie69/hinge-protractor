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

    /// Auto-lock: how far the angle may wander and still count as held still,
    /// how long it must be held, and how far it must move afterwards before a
    /// new lock can trigger. The last one stops a manual unlock from snapping
    /// straight back to locked.
    static let stillnessTolerance = 0.3
    static let stillnessDuration = 1.0
    static let rearmMovement = 2.0

    private(set) var liveDegrees = 0.0
    private(set) var lockedDegrees: Double?
    private(set) var zeroDegrees: Double?
    private(set) var sourceState: SourceState
    /// Kept unconverted for future calibration work; never drives the UI.
    private(set) var lastRawHardwareDegrees: Double?
    /// True when the current lock came from stillness rather than a tap.
    private(set) var lockedAutomatically = false
    /// Off by default: the reading following the hinge continuously is the
    /// point of the app, and an automatic lock interrupts that.
    var autoLockEnabled = false
    /// Set on first run against real hardware if closed/open turn out reversed.
    var hardwareAxisFlipped = false
    var unit: Unit = .degrees

    private var stillnessAnchor: Double?
    private var stillnessStart: TimeInterval?
    private var awaitingMovement = false

    init() {
#if DUO_SDK_AVAILABLE
        sourceState = .awaitingHardware
#else
        sourceState = .demo
#endif
    }

    /// Persistence lives outside the model so tests exercise plain values
    /// without writing to the user's real preferences.
    enum Defaults {
        static var autoLock: Bool {
            get { UserDefaults.standard.bool(forKey: "autoLock") }
            set { UserDefaults.standard.set(newValue, forKey: "autoLock") }
        }
        static var axisFlipped: Bool {
            get { UserDefaults.standard.bool(forKey: "axisFlipped") }
            set { UserDefaults.standard.set(newValue, forKey: "axisFlipped") }
        }
        static var unit: String {
            get { UserDefaults.standard.string(forKey: "unit") ?? "degrees" }
            set { UserDefaults.standard.set(newValue, forKey: "unit") }
        }
    }

    var isLocked: Bool { lockedDegrees != nil }
    var shownDegrees: Double { lockedDegrees ?? liveDegrees }
    var relativeDegrees: Double { shownDegrees - (zeroDegrees ?? 0) }
    var hasZero: Bool { zeroDegrees != nil }
    var hasHardwareHinge: Bool { sourceState.usesHardware }
    /// The slider may only drive the model while no hardware hinge is reporting.
    var acceptsDemoInput: Bool { !hasHardwareHinge }

    func receiveDemo(degrees: Double, at time: TimeInterval = now()) {
        guard acceptsDemoInput, degrees.isFinite else { return }
        liveDegrees = degrees.clamped(to: 0...180)
        checkAutoLock(at: time)
    }

    func receiveHardware(rawDegrees: Double, state: SourceState, at time: TimeInterval = now()) {
        guard rawDegrees.isFinite else { return }
        sourceState = state
        lastRawHardwareDegrees = rawDegrees
        liveDegrees = normalizeHardwareDegrees(rawDegrees)
        checkAutoLock(at: time)
    }

    static func now() -> TimeInterval { ProcessInfo.processInfo.systemUptime }

    /// Locks the reading once the angle has been held still long enough, so a
    /// measurement can be taken without watching the screen — the case where
    /// the device is wedged into a corner and no display is visible.
    ///
    /// Must be called on a timer as well as on each new sample: an input that
    /// only reports changes goes silent exactly when the angle is being held
    /// still, which is the moment this needs to fire.
    func checkAutoLock(at time: TimeInterval = now()) {
        guard autoLockEnabled, !isLocked else { return }

        if awaitingMovement {
            guard let reference = stillnessAnchor,
                  abs(liveDegrees - reference) > Self.rearmMovement else { return }
            awaitingMovement = false
            stillnessAnchor = nil
        }

        guard let anchor = stillnessAnchor, let start = stillnessStart,
              abs(liveDegrees - anchor) <= Self.stillnessTolerance else {
            stillnessAnchor = liveDegrees
            stillnessStart = time
            return
        }

        if time - start >= Self.stillnessDuration {
            lockedDegrees = liveDegrees
            lockedAutomatically = true
            stillnessAnchor = nil
            stillnessStart = nil
        }
    }

    /// The single place raw hardware coordinates become closed ≈ 0°,
    /// fully open ≈ 180°. Which way round the real hardware reports is
    /// unverified, so `hardwareAxisFlipped` makes it correctable in the UI on
    /// first run rather than requiring a rebuild.
    func normalizeHardwareDegrees(_ rawDegrees: Double) -> Double {
        guard rawDegrees.isFinite else { return 0 }
        let clamped = rawDegrees.clamped(to: 0...180)
        return hardwareAxisFlipped ? 180 - clamped : clamped
    }

    func reportNoHinge() {
        sourceState = .noHinge
        lastRawHardwareDegrees = nil
    }

    func toggleLock() {
        if isLocked {
            // Hold the released value as the reference the angle must move away
            // from, so auto-lock cannot fire again before the device is moved.
            stillnessAnchor = lockedDegrees
            stillnessStart = nil
            awaitingMovement = true
            lockedDegrees = nil
            lockedAutomatically = false
        } else {
            lockedDegrees = liveDegrees
            lockedAutomatically = false
        }
    }

    /// Uses the displayed value, so zeroing while locked records the locked
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
