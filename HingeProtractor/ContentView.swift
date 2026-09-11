import SwiftUI

struct ContentView: View {
    @State private var model = MeasurementModel()
    @State private var hasHinge = false
    @State private var demoAngle = 90.0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.04, blue: 0.07), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                Spacer(minLength: 8)
                reading
                Spacer(minLength: 8)
                if !hasHinge { demoControl }
                controls
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
        .onAppear { model.receive(degrees: demoAngle) }
        .onHingeChange { _, context in
            if let hinge = context.hinge {
                hasHinge = true
                model.receive(degrees: hinge.angle.degrees)
            } else {
                hasHinge = false
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HINGE PROTRACTOR")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                Label(hasHinge ? "Hinge connected" : "Demo mode", systemImage: hasHinge ? "checkmark.circle.fill" : "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hasHinge ? .green : .orange)
            }
            Spacer()
            Picker("Unit", selection: $model.unit) {
                ForEach(MeasurementModel.Unit.allCases) { unit in
                    Text(unit == .degrees ? "°" : "rad").tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    private var reading: some View {
        VStack(spacing: 12) {
            Text(model.formatted(model.relativeDegrees, signed: model.hasZero))
                .font(.system(size: 72, weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(model.hasZero ? "RELATIVE ANGLE" : "HINGE ANGLE")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(.secondary)

            if model.hasZero {
                Text("Absolute  \(model.formatted(model.shownDegrees))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if model.isFrozen {
                Label("Reading frozen", systemImage: "snowflake")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.cyan)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.hasZero ? "Relative angle" : "Hinge angle")
        .accessibilityValue(model.formatted(model.relativeDegrees, signed: model.hasZero))
    }

    private var demoControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Simulated hinge")
                Spacer()
                Text("\(demoAngle, specifier: "%.1f")°")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Slider(value: $demoAngle, in: 0...180, step: 0.1)
                .tint(.orange)
                .onChange(of: demoAngle) { _, value in
                    model.receive(degrees: value)
                }
        }
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(action: model.toggleFreeze) {
                Label(model.isFrozen ? "Resume" : "Freeze", systemImage: model.isFrozen ? "play.fill" : "snowflake")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(active: model.isFrozen))

            HStack(spacing: 12) {
                Button(action: model.setZero) {
                    Label("Set Zero", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: model.clearZero) {
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!model.hasZero)
            }
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 17)
            .background(active ? Color.cyan : Color.blue, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 15)
            .background(.white.opacity(configuration.isPressed ? 0.16 : 0.1), in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
}

