import Testing
@testable import HingeProtractor

struct HingeAngleModelTests {
    @Test func zeroCreatesRelativeMeasurement() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 75)
        model.setZero()
        model.receiveDemo(degrees: 92.5)
        #expect(model.relativeDegrees == 17.5)
    }

    @Test func freezeKeepsReadingUntilResumed() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 45)
        model.toggleFreeze()
        model.receiveDemo(degrees: 100)
        #expect(model.shownDegrees == 45)
        model.toggleFreeze()
        #expect(model.shownDegrees == 100)
    }

    @Test func inputIsLimitedToPhysicalRange() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 240, state: .hardware)
        #expect(model.liveDegrees == 180)
    }

    @Test func hardwareNormalizationIsCentralized() {
        let model = HingeAngleModel()
        #expect(model.normalizeHardwareDegrees(90) == 90)
    }
}
