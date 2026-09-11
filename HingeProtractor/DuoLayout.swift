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
/// Measuring happens while the device is partially open, so the display is
/// physically bent the whole time it is in use. Two consequences:
///
/// 1. Text must not cross the crease — it would be split across two planes
///    meeting at an angle.
/// 2. The instrument face *should* cross it, with its vertex exactly on the
///    fold, so the drawing pivots about the same line the hardware does. (It
///    does not overlay the device 1:1 — that would require looking down the
///    hinge axis, which is impossible while looking at a screen mounted on it.)
///
/// Apple's guidance is that layout comes from the arrangement and reserved
/// region APIs, never from the hinge angle; the angle drives interaction only.
/// `ArrangementView` is the recommended split container, but this screen needs
/// one element deliberately spanning the fold and text confined to each side,
/// so it positions against the division region directly.
///
/// UNVERIFIED: written against the API names in Apple's tech talks and never
/// compiled, because the iOS 27 SDK was not available. Expect to fix
/// signatures on the first build with Xcode 27.1.
struct DuoSplitLayout: View {
    let model: HingeAngleModel
    @Binding var demoAngle: Double
    @State private var fold: CGRect?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            if let fold, fold.width > 0 {
                bentLayout(size: size, fold: fold)
            } else {
                SingleColumnLayout(model: model, demoAngle: $demoAngle)
            }
        }
        .onGeometryChange(for: CGRect?.self) { proxy in
            proxy.reservedRegions(kind: .division).first?.frame
        } action: { region in
            fold = region
        }
    }

    @ViewBuilder
    private func bentLayout(size: CGSize, fold: CGRect) -> some View {
        // The fold is vertical when the device is unfolded wide, and horizontal
        // in the "sit" posture — folded back and stood on a desk, which is both
        // the measuring posture and how it rests on a table. Apple's convention
        // there is content on the upper half, controls on the lower one.
        if fold.width >= fold.height {
            ZStack {
                HingeArcView(degrees: model.shownDegrees,
                             vertex: UnitPoint(x: 0.5, y: fold.midY / max(size.height, 1)),
                             showsNumerals: false)
                    .animation(InstrumentTheme.settle, value: model.shownDegrees)
                VStack(spacing: 0) {
                    readingHalf.frame(height: fold.minY)
                    Color.clear.frame(height: fold.height)
                    controlsHalf.frame(height: max(size.height - fold.maxY, 0))
                }
            }
        } else {
            ZStack {
                HingeArcView(degrees: model.shownDegrees,
                             vertex: UnitPoint(x: fold.midX / max(size.width, 1), y: 0.88))
                    .animation(InstrumentTheme.settle, value: model.shownDegrees)
                HStack(spacing: 0) {
                    readingHalf.frame(width: fold.minX)
                    Color.clear.frame(width: fold.width)
                    controlsHalf.frame(width: max(size.width - fold.maxX, 0))
                }
            }
        }
    }

    /// The half that faces the user in the sit posture: the reading, nothing else.
    private var readingHalf: some View {
        VStack(spacing: 14) {
            StatusHeader(model: model)
            Spacer(minLength: 0)
            ReadingView(model: model, primaryFontSize: 58)
            Spacer(minLength: 0)
        }
        .padding(22)
    }

    /// The half lying flat under the user's fingers. The reading is repeated
    /// small, because once bent the two halves face different directions and
    /// only one of them may be visible.
    private var controlsHalf: some View {
        VStack(spacing: 14) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(InstrumentTheme.readout(34))
                .foregroundStyle(InstrumentTheme.textDim)
                .minimumScaleFactor(0.4).lineLimit(1)
                .animation(InstrumentTheme.settle, value: model.relativeDegrees)
            Spacer(minLength: 0)
            if model.acceptsDemoInput {
                DemoSliderView(model: model, demoAngle: $demoAngle)
            }
            ControlsView(model: model)
        }
        .padding(22)
    }
}

/// Shown on the cover display while the inner display carries the main UI.
///
/// Which display a person can actually see depends on whether they are
/// measuring an interior or an exterior angle — pressed into a wall corner the
/// cover display faces the wall, held around an outside corner the inner
/// display does. The device cannot tell those apart, so the reading goes on
/// both rather than guessing.
///
/// UNVERIFIED: `sceneAccessory` has never been compiled here.
struct OuterReadingView: View {
    let model: HingeAngleModel

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 8) {
                Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                    .font(InstrumentTheme.readout(56))
                    .foregroundStyle(InstrumentTheme.text)
                    .minimumScaleFactor(0.4).lineLimit(1)
                    .animation(InstrumentTheme.settle, value: model.relativeDegrees)
                Text(model.hasZero ? "相对角" : "开合角")
                    .font(InstrumentTheme.caption).tracking(4)
                    .foregroundStyle(InstrumentTheme.textFaint)
                if model.isLocked {
                    Text(model.lockedAutomatically ? "自动锁定" : "已锁定")
                        .font(InstrumentTheme.caption).tracking(3)
                        .foregroundStyle(InstrumentTheme.accent)
                }
            }
            .padding(24)
        }
    }
}

#endif
