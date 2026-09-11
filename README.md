# Hinge Protractor

Turn an iPhone Duo into a physical protractor: place the two halves of the
device against the sides of an angle and read the hinge measurement live.

## Features

- Live hinge angle with one-decimal precision
- Relative measurement with Set Zero and Clear Zero
- Freeze/unfreeze the displayed reading
- Degrees and radians
- Demo slider on devices without a hinge, including Simulator
- No analytics, account, network access, or stored measurements

## Requirements

- Xcode 27 and iOS 27 for live hinge measurements
- Xcode 16 / iOS 18 or newer for demo-only development
- iPhone Duo for physical measurements

The app still runs on other iOS devices. When the Hinge API reports no hinge,
it displays a demo slider so the interface can be tested in Simulator.

## Build

1. Open `HingeProtractor.xcodeproj` in Xcode.
2. Select the `HingeProtractor` scheme.
3. Choose an iPhone Duo or Simulator and run.

If signing fails on a physical device, select the app target, open **Signing &
Capabilities**, and choose your development team.

Older Xcode versions do not know the Hinge API. The live listener is isolated
behind compiler and availability checks, so those toolchains build demo mode
without trying to resolve `onHingeChange`.

## Calibration and accuracy

The physical hinge coordinate has not yet been checked on shipping hardware.
The app currently assumes closed is approximately 0° and fully open is 180°;
that conversion is centralized in `normalizeHardwareDegrees(_:)`.

For a practical calibration check, remove or account for the case, place both
halves against a known 90° corner, and use **Set Zero** only when taking a
relative measurement from that reference. Case thickness, mechanical play,
surface contact, and the definition of the hinge zero may introduce roughly
1°–2° of error.

## How it works

SwiftUI's `onHingeChange` modifier supplies continuous hinge updates. A `nil`
hinge means the current device has no hinge. The measurement model keeps the
raw angle separate from display state so freezing and zeroing remain
predictable.

Apple reference: [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/)

## Status

Early prototype. Suitable only for casual DIY, craft, and educational use.
It is not a calibrated measuring instrument and must not be used for
safety-critical or precision engineering work.

## License

[MIT](LICENSE)
