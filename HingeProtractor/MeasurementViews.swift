import SwiftUI

/// Building blocks shared by the single-screen layout and the iPhone Duo
/// split layout. Text is self-contained so it can live entirely on one half of
/// a bent inner display; only the instrument face is allowed to cross the fold,
/// because it depicts the device itself.

enum InstrumentTheme {
    static let base = Color(red: 0.075, green: 0.075, blue: 0.082)
    static let baseDeep = Color(red: 0.035, green: 0.035, blue: 0.039)
    static let accent = Color(red: 0.78, green: 0.66, blue: 0.42)
    static let accentBright = Color(red: 0.89, green: 0.79, blue: 0.58)
    static let text = Color(white: 0.93)
    static let textDim = Color(white: 0.52)
    static let textFaint = Color(white: 0.34)
    static let engravingBright = Color(white: 0.42)
    static let engraving = Color(white: 0.26)
    static let engravingFaint = Color(white: 0.16)

    /// Damped settling rather than a linear follow — the reading should feel
    /// like a weighted mechanism coming to rest.
    static let settle = Animation.interpolatingSpring(stiffness: 170, damping: 24)

    static func readout(_ size: CGFloat) -> Font {
        .system(size: size, weight: .ultraLight).monospacedDigit()
    }

    static var caption: Font {
        .system(size: 11, weight: .medium).width(.expanded)
    }
}

struct StatusHeader: View {
    let model: HingeAngleModel
    var compact = false
    @State private var showingSettings = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if !compact {
                    Text("HINGE PROTRACTOR")
                        .font(.system(size: 10, weight: .medium)).tracking(3)
                        .foregroundStyle(InstrumentTheme.textDim)
                        .lineLimit(1).fixedSize()
                }
                Text(model.sourceState.label)
                    .font(.system(size: 11, weight: .regular)).tracking(1)
                    .foregroundStyle(model.hasHardwareHinge
                                     ? InstrumentTheme.accent : InstrumentTheme.textFaint)
            }
            Spacer(minLength: 12)
            UnitPicker(model: model)
            Button { showingSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(InstrumentTheme.textDim)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("设置")
        }
        .sheet(isPresented: $showingSettings) { SettingsSheet(model: model) }
    }
}

struct SettingsSheet: View {
    @Bindable var model: HingeAngleModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("稳定后自动锁定", isOn: $model.autoLockEnabled)
                } footer: {
                    Text("角度保持不动约一秒后自动锁定读数，并以触感确认。关闭时读数始终跟随铰链。")
                }
                Section {
                    Toggle("反转铰链方向", isOn: $model.hardwareAxisFlipped)
                } footer: {
                    Text("若合拢与展开的读数相反，打开此项。仅影响硬件铰链数据。")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
        .tint(InstrumentTheme.accent)
    }
}

struct UnitPicker: View {
    @Bindable var model: HingeAngleModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HingeAngleModel.Unit.allCases) { unit in
                let selected = model.unit == unit
                Button { model.unit = unit } label: {
                    Text(unit == .degrees ? "DEG" : "RAD")
                        .font(.system(size: 10, weight: .medium)).tracking(1)
                        .foregroundStyle(selected ? InstrumentTheme.accent : InstrumentTheme.textFaint)
                        .frame(width: 42, height: 28)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(unit == .degrees ? "度" : "弧度")
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .background {
            let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
            shape.stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

struct ReadingView: View {
    let model: HingeAngleModel
    var primaryFontSize: CGFloat = 72

    var body: some View {
        VStack(spacing: 6) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(InstrumentTheme.readout(primaryFontSize))
                .foregroundStyle(InstrumentTheme.text)
                .minimumScaleFactor(0.4).lineLimit(1)
                .contentTransition(.numericText())
                .animation(InstrumentTheme.settle, value: model.relativeDegrees)
            Text(model.hasZero ? "相对角" : "开合角")
                .font(InstrumentTheme.caption).tracking(4)
                .foregroundStyle(InstrumentTheme.textFaint)
            if model.hasZero {
                Text(model.formatted(model.shownDegrees))
                    .font(.system(size: 13, weight: .light).monospacedDigit())
                    .foregroundStyle(InstrumentTheme.textDim)
            }
            if model.isLocked {
                Text(model.lockedAutomatically ? "自动锁定" : "已锁定")
                    .font(InstrumentTheme.caption).tracking(3)
                    .foregroundStyle(InstrumentTheme.accent)
                    .padding(.top, 2)
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
        VStack(spacing: 6) {
            HStack {
                Text("演示铰链").tracking(1)
                Spacer()
                Text("\(demoAngle, specifier: "%.1f")°").monospacedDigit()
            }
            .font(.system(size: 10, weight: .regular))
            .foregroundStyle(InstrumentTheme.textFaint)
            Slider(value: $demoAngle, in: 0...180, step: 0.1)
                .tint(InstrumentTheme.accent.opacity(0.7))
                .onChange(of: demoAngle) { _, value in model.receiveDemo(degrees: value) }
                .accessibilityLabel("演示铰链角度")
                .accessibilityValue(Text(String(format: "%.1f 度", demoAngle)))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background {
            let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
            shape.fill(Color.white.opacity(0.025))
                .overlay(shape.stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
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
            Text("设为零").lineLimit(1).frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var clearButton: some View {
        Button(action: model.clearZero) {
            Text("清零").lineLimit(1).frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!model.hasZero)
        .opacity(model.hasZero ? 1 : 0.35)
    }
}

struct AppBackground: View {
    var body: some View {
        RadialGradient(colors: [InstrumentTheme.base, InstrumentTheme.baseDeep],
                       center: .center, startRadius: 0, endRadius: 620)
            .ignoresSafeArea()
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let active: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(active ? InstrumentTheme.baseDeep : InstrumentTheme.accentBright)
            .padding(.vertical, 15)
            .background {
                let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
                if active {
                    shape.fill(InstrumentTheme.accent)
                } else {
                    shape.fill(Color.white.opacity(0.03)).overlay(
                        shape.stroke(InstrumentTheme.accent.opacity(0.55), lineWidth: 1))
                }
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(InstrumentTheme.textDim)
            .padding(.vertical, 13)
            .background {
                let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
                shape.fill(Color.white.opacity(configuration.isPressed ? 0.08 : 0.035))
                    .overlay(shape.stroke(Color.white.opacity(0.07), lineWidth: 1))
            }
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
