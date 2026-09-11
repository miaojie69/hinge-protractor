# Hinge Protractor

The idea: place the two halves of a folding iPhone against the two sides of an
angle and read the hinge opening directly. Today this repository ships the
**demo mode** of that idea — the measurement UI, driven by a simulated angle
slider instead of a sensor.

## Verification status

| Path | Status |
| --- | --- |
| Demo mode (slider input) | Built and run in iOS Simulator; model unit tests pass |
| Hardware hinge path | **Not verified.** Needs the iOS 27 SDK; compiled out by default |
| Physical measurement accuracy | **Not measured.** No hardware has been tested |

Nothing in this repository has been run on a folding device. Do not read
"demo verified" as "hardware works".

## Features

- Hinge angle displayed in degrees to one decimal place (a display format, not
  an accuracy claim)
- Large relative reading (displayed angle − zero point) with the absolute angle
  always visible alongside
- Set Zero / Clear Zero; zeroing while frozen uses the frozen reading
- Freeze/resume — the display holds while input keeps arriving in the background
- Degrees and radians, applied to both readings
- Demo slider, two arms, and a sector that follows the absolute opening angle
- VoiceOver labels on the readings; the decorative sector is hidden from
  the accessibility tree
- No analytics, account, network access, or stored measurements

## The hardware path

The API this app is designed around is real. Apple's tech talk
[Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/)
documents `onHingeChange`, `context.hinge`, `hinge.status` (closed /
partiallyOpen / fullyOpen) and `hinge.angle`. It ships in the **iOS 27 SDK**;
the iPhone Duo simulator arrives with **Xcode 27.1**, in beta from late
September 2026.

This work was done on Xcode 26.1.1 / iOS 26.1 SDK — one major version earlier.
That SDK declares none of those symbols (verified by searching its SwiftUI
module interfaces), and `simctl list devicetypes` offers no folding device.
So the hardware path cannot be compiled, let alone verified, on this toolchain.

An earlier revision guarded the listener with `#if compiler(>=6.3)` plus
`if #available(iOS 27.0, *)`. The intent was right, but a compiler version does
not prove the selected SDK declares a symbol, and runtime availability cannot
make an older SDK resolve an interface it never had. Every reference now sits
behind one explicit build flag, `HINGE_API_AVAILABLE`, **off by default**.

Once Xcode 27.1 is installed, add `HINGE_API_AVAILABLE` to
`SWIFT_ACTIVE_COMPILATION_CONDITIONS` for the app target to compile the
hardware path. Turning the flag on does not by itself demonstrate hardware
support — the coordinate convention and accuracy still need checking against a
real device.

## Source states

The app distinguishes three situations an earlier version conflated:

- **演示模式** — the hardware path is compiled out; the slider is the only input.
- **等待硬件信息…** — the hardware path is compiled in but no callback has
  arrived. This is *not* evidence that the device lacks a hinge.
- **本机无铰链** — the hardware path explicitly reported no hinge.

While a hardware hinge is reporting, the slider is hidden and demo input is
rejected, so it cannot overwrite sensor data.

## Requirements

- Demo mode: Xcode 26.1.1 with the iOS 26.1 SDK and an iOS Simulator runtime.
  Verified working.
- Hardware path: Xcode 27.1 with the iOS 27 SDK, plus an iPhone Duo (or its
  simulator) to check the hinge coordinate convention. Not available for this
  work.

## Build

```bash
xcodebuild -project HingeProtractor.xcodeproj -scheme HingeProtractor \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Or open `HingeProtractor.xcodeproj` in Xcode, pick the `HingeProtractor`
scheme and a simulator, and Run. Signing is not needed for the simulator; for a
physical device, select the app target → **Signing & Capabilities** → your team.

## Calibration and accuracy

**Accuracy is unverified.** No measurement against a reference angle has been
performed. Any real-world error depends on contact between the device halves
and the measured surfaces, case thickness, mechanical play in the hinge, and
where the hinge's own zero sits. The one-decimal display is a formatting
choice and does not imply that level of precision.

Set Zero and calibration are different operations:

- **Set Zero** records the current displayed angle as a reference and reports
  change relative to it. Zeroing at a known 90° corner gives you deviation from
  that corner — it does not correct the absolute reading to 90°.
- **Calibration** would mean correcting the absolute angle against a reference.
  This app does not do that.

The raw hardware value is retained separately (`lastRawHardwareDegrees`) so a
future calibration step has something to work from. All coordinate conversion
is confined to `normalizeHardwareDegrees(_:)`; if real hardware turns out to
report fully open as 0°, only that function changes.

## Status

Early prototype and an open-source demo. Not a calibrated measuring
instrument; not for safety-critical or precision engineering work.

## License

[MIT](LICENSE)
