import Testing
@testable import HingeProtractor

struct MeasurementModelTests {
    @Test func zeroCreatesRelativeMeasurement() {
        let model = MeasurementModel()
        model.receive(degrees: 75)
        model.setZero()
        model.receive(degrees: 92.5)

        #expect(model.relativeDegrees == 17.5)
    }

    @Test func freezeKeepsReadingUntilResumed() {
        let model = MeasurementModel()
        model.receive(degrees: 45)
        model.toggleFreeze()
        model.receive(degrees: 100)

        #expect(model.shownDegrees == 45)
        model.toggleFreeze()
        #expect(model.shownDegrees == 100)
    }

    @Test func inputIsLimitedToPhysicalRange() {
        let model = MeasurementModel()
        model.receive(degrees: 240)
        #expect(model.liveDegrees == 180)
    }
}
