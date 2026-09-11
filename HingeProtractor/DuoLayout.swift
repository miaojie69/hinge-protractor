import SwiftUI

/// Picks the layout for the current device and posture.
struct MeasurementLayout: View {
    let model: HingeAngleModel
    @Binding var demoAngle: Double

    var body: some View {
#if DUO_SDK_AVAILABLE
        DuoSplitLayout(model: model, demoAngle: $demoAngle)
#else
        SingleColumnLayout(model: model, demoAngle: $demoAngle)
#endif
    }
}

#if DUO_SDK_AVAILABLE

/// iPhone Duo inner display.
///
/// Measuring happens while the device is *partially open*, so the inner display
/// is physically bent along the fold. A single centred column would put the
/// large reading directly on the crease, split across two planes meeting at an
/// angle. Apple's guidance is that layout must come from the arrangement and
/// reserved-region APIs, never from the hinge angle — the hinge angle drives
/// interaction only.
///
/// So: when an active `.division` region exists (the fold, which reports zero
/// width when the device is flat), split into two self-contained halves.
/// Otherwise — flat inner display, cover display, or any other device — fall
/// back to the single column.
///
/// UNVERIFIED: written against the API names in Apple's tech talks. It has
/// never been compiled, because the iOS 27 SDK was not available. Expect to fix
/// signatures on first build with Xcode 27.1.
struct DuoSplitLayout: View {
    let model: HingeAngleModel
    @Binding var demoAngle: Double
    @State private var foldIsActive = false

    var body: some View {
        Group {
            if foldIsActive {
                ArrangementView {
                    readingHalf
                } secondary: {
                    controlsHalf
                }
                .arrangementViewStyle(.split.axes(.horizontal))
            } else {
                SingleColumnLayout(model: model, demoAngle: $demoAngle)
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            !proxy.reservedRegions(kind: .division).isEmpty
        } action: { isActive in
            foldIsActive = isActive
        }
    }

    /// One half: status and the measurement itself, sized for roughly 445x626pt.
    private var readingHalf: some View {
        VStack(spacing: 16) {
            StatusHeader(model: model)
            Spacer(minLength: 0)
            ReadingView(model: model, primaryFontSize: 64)
            HingeArcView(degrees: model.shownDegrees).frame(height: 180)
            Spacer(minLength: 0)
        }
        .padding(20)
    }

    /// The other half: controls, plus a compact copy of the reading. The two
    /// halves face different directions while measuring, so whichever one the
    /// user can see must show the number.
    private var controlsHalf: some View {
        VStack(spacing: 16) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(.system(size: 40, weight: .light, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            if model.acceptsDemoInput {
                DemoSliderView(model: model, demoAngle: $demoAngle)
            }
            ControlsView(model: model)
        }
        .padding(20)
    }
}

#endif
