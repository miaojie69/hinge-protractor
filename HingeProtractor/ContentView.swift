import SwiftUI

struct ContentView: View {
    // Owned by the app so the outer-display accessory can show the same model.
    let model: HingeAngleModel
    @Binding var demoAngle: Double

    private let stillnessTicker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    /// Detents every 15°, so opening the device feels like turning a graduated
    /// instrument rather than sweeping a continuous slider.
    @State private var lastDetent: Double?
    private let detentSpacing = 15.0
    private let detentWidth = 0.8

    private func reportDetent(crossing angle: Double) {
        let nearest = (angle / detentSpacing).rounded() * detentSpacing
        guard abs(angle - nearest) <= detentWidth else {
            lastDetent = nil
            return
        }
        guard lastDetent != nearest else { return }
        lastDetent = nearest
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
    }

    var body: some View {
        ZStack {
            AppBackground()
            MeasurementLayout(model: model, demoAngle: $demoAngle)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            model.autoLockEnabled = HingeAngleModel.Defaults.autoLock
            model.hardwareAxisFlipped = HingeAngleModel.Defaults.axisFlipped
            model.unit = HingeAngleModel.Unit(rawValue: HingeAngleModel.Defaults.unit) ?? .degrees
            model.receiveDemo(degrees: demoAngle)
        }
        .onChange(of: model.autoLockEnabled) { _, new in HingeAngleModel.Defaults.autoLock = new }
        .onChange(of: model.hardwareAxisFlipped) { _, new in HingeAngleModel.Defaults.axisFlipped = new }
        .onChange(of: model.unit) { _, new in HingeAngleModel.Defaults.unit = new.rawValue }
        .onReceive(stillnessTicker) { _ in model.checkAutoLock() }
        .onChange(of: model.isLocked, initial: true) { _, locked in
            // While measuring, nobody is touching the screen — don't let it sleep
            // mid-measurement. Allow it again once the reading is locked.
            UIApplication.shared.isIdleTimerDisabled = !locked
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onChange(of: model.acceptsDemoInput) { _, acceptsDemo in
            // Returning from hardware to demo: start the slider where the reading is.
            if acceptsDemo { demoAngle = model.liveDegrees }
        }
        .onChange(of: model.isLocked) { _, locked in
            // The point of auto-lock is measuring without watching the screen,
            // so the confirmation has to be felt rather than seen.
            if locked && model.lockedAutomatically {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }
        .onChange(of: model.liveDegrees) { _, angle in reportDetent(crossing: angle) }
        .modifier(HingeListener(model: model))
    }
}

/// Single-column layout: iPhone, iPad, and the iPhone Duo cover display.
/// The Duo inner display uses `DuoSplitLayout` instead — see DuoLayout.swift.
struct SingleColumnLayout: View {
    let model: HingeAngleModel
    @Binding var demoAngle: Double

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatusHeader(model: model)
                ReadingView(model: model)
                HingeArcView(degrees: model.shownDegrees).frame(height: 190)
                if model.acceptsDemoInput { DemoSliderView(model: model, demoAngle: $demoAngle) }
                ControlsView(model: model)
            }
            .padding(24)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Isolates every reference to the unreleased iPhone Duo APIs behind one build
/// flag. It is OFF by default: no SDK shipping today (checked through iOS 26.1)
/// declares `onHingeChange`, and a compiler-version check cannot prove the
/// selected SDK contains a symbol. Enable DUO_SDK_AVAILABLE only with the
/// iOS 27 SDK, then verify the build — never as a way to claim hardware support.
private struct HingeListener: ViewModifier {
    let model: HingeAngleModel

    @ViewBuilder
    func body(content: Content) -> some View {
#if DUO_SDK_AVAILABLE
        content.onHingeChange { _, context in
            guard let hinge = context.hinge else {
                model.reportNoHinge()
                return
            }
            let state: HingeAngleModel.SourceState
            switch hinge.status {
            case .closed: state = .closed
            case .partiallyOpen: state = .partiallyOpen
            case .fullyOpen: state = .fullyOpen
            default: state = .hardwareUnknown
            }
            // Coordinate conversion belongs only in the model function.
            model.receiveHardware(rawDegrees: hinge.angle.degrees, state: state)
        }
#else
        content
#endif
    }
}

#Preview {
    @Previewable @State var model = HingeAngleModel()
    @Previewable @State var demoAngle = 90.0
    ContentView(model: model, demoAngle: $demoAngle)
}
