import SwiftUI

/// Building blocks shared by the single-screen layout and the iPhone Duo
/// split layout. Each one is self-contained so it can live entirely on one
/// half of a bent inner display without spanning the fold.

struct StatusHeader: View {
    let model: HingeAngleModel
    var compact = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 5) {
                if !compact {
                    Text("HINGE PROTRACTOR")
                        .font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                }
                Label(model.sourceState.label,
                      systemImage: model.hasHardwareHinge ? "checkmark.circle.fill" : "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(model.hasHardwareHinge ? .green : .orange)
            }
            Spacer(minLength: 12)
            UnitPicker(model: model)
        }
    }
}

struct UnitPicker: View {
    @Bindable var model: HingeAngleModel

    var body: some View {
        Picker("单位", selection: $model.unit) {
            ForEach(HingeAngleModel.Unit.allCases) { unit in
                Text(unit == .degrees ? "°" : "rad").tag(unit)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 120)
    }
}

struct ReadingView: View {
    let model: HingeAngleModel
    var primaryFontSize: CGFloat = 72

    var body: some View {
        VStack(spacing: 10) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(.system(size: primaryFontSize, weight: .light, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                .contentTransition(.numericText())
            Text(model.hasZero ? "RELATIVE ANGLE" : "HINGE ANGLE")
                .font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
            Text("绝对角  \(model.formatted(model.shownDegrees))")
                .font(.headline.monospacedDigit()).foregroundStyle(.secondary)
            if model.isLocked {
                Label(model.lockedAutomatically ? "已自动锁定" : "角度已锁定", systemImage: "lock.fill")
                    .font(.callout.weight(.semibold)).foregroundStyle(.cyan)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.hasZero ? "相对角" : "铰链角")
        .accessibilityValue(Text(model.accessibleReading))
    }
}

struct DemoSliderView: View {
    let model: HingeAngleModel
    @Binding var demoAngle: Double

    var body: some View {
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
}

struct ControlsView: View {
    @Bindable var model: HingeAngleModel

    var body: some View {
        VStack(spacing: 12) {
            Button(action: model.toggleLock) {
                Label(model.isLocked ? "解除锁定" : "锁定角度",
                      systemImage: model.isLocked ? "lock.open.fill" : "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(active: model.isLocked))
            Toggle(isOn: $model.autoLockEnabled) {
                Label("稳定后自动锁定", systemImage: "hand.raised.fill")
                    .font(.subheadline).lineLimit(1)
            }
            .tint(.blue)
            .padding(.horizontal, 4)
            // Side by side normally; stacked once large Dynamic Type sizes or a
            // narrow half-screen make the labels wrap into uneven columns.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { zeroButton; clearButton }
                VStack(spacing: 12) { zeroButton; clearButton }
            }
        }
    }

    private var zeroButton: some View {
        Button(action: model.setZero) {
            Label("设为零", systemImage: "scope").lineLimit(1).frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var clearButton: some View {
        Button(action: model.clearZero) {
            Label("清零", systemImage: "arrow.counterclockwise").lineLimit(1).frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!model.hasZero)
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.03, green: 0.04, blue: 0.07), .black],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.vertical, 17)
            .background(active ? Color.cyan : Color.blue, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white).opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).padding(.vertical, 15)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.1), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}

extension HingeAngleModel {
    var accessibleReading: String {
        let unitWord = unit == .degrees ? "度" : "弧度"
        let main = formatted(relativeDegrees, signed: hasZero)
            .replacingOccurrences(of: unit.symbol, with: " " + unitWord)
        let absolute = formatted(shownDegrees)
            .replacingOccurrences(of: unit.symbol, with: " " + unitWord)
        var parts = [main, "绝对角 \(absolute)"]
        if isLocked { parts.append(lockedAutomatically ? "已自动锁定" : "角度已锁定") }
        return parts.joined(separator: "，")
    }
}
