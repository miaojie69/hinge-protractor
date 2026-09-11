import SwiftUI

@main
struct HingeProtractorApp: App {
    /// Held here, not in ContentView, so the outer-display accessory reads the
    /// same measurement as the inner display.
    @State private var model = HingeAngleModel()
    @State private var demoAngle = 90.0

    var body: some Scene {
        mainScene
    }

#if DUO_SDK_AVAILABLE
    /// Mirrors the reading onto the cover display. Which display a person can
    /// actually see depends on whether they are measuring an interior or an
    /// exterior angle, and the device cannot tell those apart — so show the
    /// number on both rather than guessing.
    ///
    /// UNVERIFIED: `sceneAccessory` is taken from Apple's tech talk, never
    /// compiled. Expect the signature to need fixing on the first real build.
    private var mainScene: some Scene {
        WindowGroup {
            ContentView(model: model, demoAngle: $demoAngle)
        }
        .sceneAccessory {
            OuterReadingView(model: model)
        }
    }
#else
    private var mainScene: some Scene {
        WindowGroup {
            ContentView(model: model, demoAngle: $demoAngle)
        }
    }
#endif
}
