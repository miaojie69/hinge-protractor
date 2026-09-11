import SwiftUI

struct ContentView: View {
    @State private var model = HingeAngleModel()
    @State private var demoAngle = 90.0

    var body: some View {
        ZStack {
            AppBackground()
            MeasurementLayout(model: model, demoAngle: $demoAngle)
        }
        .preferredColorScheme(.dark)
        .onAppear { model.receiveDemo(degrees: demoAngle) }
        .onChange(of: model.acceptsDemoInput) { _, acceptsDemo in
            // Returning from hardware to demo: start the slider where the reading is.
            if acceptsDemo { demoAngle = model.liveDegrees }
        }
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

#Preview { ContentView() }
