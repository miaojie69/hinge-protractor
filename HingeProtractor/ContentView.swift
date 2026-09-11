import SwiftUI

struct ContentView: View {
    @State private var model = HingeAngleModel()
    @State private var demoAngle = 90.0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.04, blue: 0.07), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    reading
                    HingeArcView(degrees: model.shownDegrees).frame(height: 190)
                    if model.acceptsDemoInput { demoControl }
                    controls
                }
                .padding(24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { model.receiveDemo(degrees: demoAngle) }
        .onChange(of: model.acceptsDemoInput) { _, acceptsDemo in
            // Returning from hardware to demo: start the slider where the reading is.
            if acceptsDemo { demoAngle = model.liveDegrees }
        }
        .modifier(HingeListener(model: model))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("HINGE PROTRACTOR").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                Label(model.sourceState.label, systemImage: model.hasHardwareHinge ? "checkmark.circle.fill" : "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.hasHardwareHinge ? .green : .orange)
            }
            Spacer()
            Picker("Unit", selection: $model.unit) {
                ForEach(HingeAngleModel.Unit.allCases) { unit in
                    Text(unit == .degrees ? "°" : "rad").tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    private var reading: some View {
        VStack(spacing: 10) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(.system(size: 72, weight: .light, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
                .contentTransition(.numericText())
            Text(model.hasZero ? "RELATIVE ANGLE" : "HINGE ANGLE")
                .font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
            Text("绝对角  \(model.formatted(model.shownDegrees))")
                .font(.headline.monospacedDigit()).foregroundStyle(.secondary)
            if model.isFrozen {
                Label("读数已冻结", systemImage: "snowflake")
                    .font(.callout.weight(.semibold)).foregroundStyle(.cyan)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.hasZero ? "相对角" : "铰链角")
        .accessibilityValue(Text(accessibleReading))
    }

    private var accessibleReading: String {
        let unitWord = model.unit == .degrees ? "度" : "弧度"
        let main = model.formatted(model.relativeDegrees, signed: model.hasZero)
            .replacingOccurrences(of: model.unit.symbol, with: " " + unitWord)
        let absolute = model.formatted(model.shownDegrees)
            .replacingOccurrences(of: model.unit.symbol, with: " " + unitWord)
        var parts = [main, "绝对角 \(absolute)"]
        if model.isFrozen { parts.append("读数已冻结") }
        return parts.joined(separator: "，")
    }

    private var demoControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("演示铰链")
                Spacer()
                Text("\(demoAngle, specifier: "%.1f")°").monospacedDigit()
            }
            .font(.caption).foregroundStyle(.secondary)
            Slider(value: $demoAngle, in: 0...180, step: 0.1)
                .tint(.orange)
                .onChange(of: demoAngle) { _, value in model.receiveDemo(degrees: value) }
                .accessibilityLabel("演示铰链角度")
                .accessibilityValue(Text(String(format: "%.1f 度", demoAngle)))
        }
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: model.toggleFreeze) {
                Label(model.isFrozen ? "继续" : "冻结", systemImage: model.isFrozen ? "play.fill" : "snowflake")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(active: model.isFrozen))
            HStack(spacing: 12) {
                Button(action: model.setZero) {
                    Label("设为零", systemImage: "scope").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                Button(action: model.clearZero) {
                    Label("清零", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle()).disabled(!model.hasZero)
            }
        }
    }
}

/// Isolates every reference to the unreleased hinge API behind one build flag.
/// It is OFF by default: no SDK shipping today (checked through iOS 26.1)
/// declares `onHingeChange`, and a compiler-version check cannot prove the
/// selected SDK contains a symbol. Enable HINGE_API_AVAILABLE only after
/// confirming the declaration in an SDK you actually have, then verify the
/// build — never as a way to claim hardware support.
private struct HingeListener: ViewModifier {
    let model: HingeAngleModel

    @ViewBuilder
    func body(content: Content) -> some View {
#if HINGE_API_AVAILABLE
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

private struct PrimaryButtonStyle: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.vertical, 17)
            .background(active ? Color.cyan : Color.blue, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white).opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.vertical, 15)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.1), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}

#Preview { ContentView() }
