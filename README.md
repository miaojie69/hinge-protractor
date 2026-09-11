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

- Xcode 27 or newer
- iOS 27 or newer
- iPhone Duo for physical measurements

The app still runs on other iOS devices. When the Hinge API reports no hinge,
it displays a demo slider so the interface can be tested in Simulator.

## Build

1. Open `HingeProtractor.xcodeproj` in Xcode.
2. Select the `HingeProtractor` scheme.
3. Choose an iPhone Duo or Simulator and run.

If signing fails on a physical device, select the app target, open **Signing &
Capabilities**, and choose your development team.

## How it works

SwiftUI's `onHingeChange` modifier supplies continuous hinge updates. A `nil`
hinge means the current device has no hinge. The measurement model keeps the
raw angle separate from display state so freezing and zeroing remain
predictable.

Apple reference: [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/)

## Status

Early prototype. Do not use it for safety-critical or precision engineering
work until accuracy has been validated against calibrated instruments.
