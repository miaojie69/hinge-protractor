import Testing
@testable import HingeProtractor

struct HingeAngleModelTests {
    @Test func zeroCreatesRelativeMeasurement() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 90)
        model.setZero()
        model.receiveDemo(degrees: 120)
        #expect(model.relativeDegrees == 30)
        #expect(model.shownDegrees == 120)
    }

    @Test func relativeAngleStaysNegativeBelowZeroPoint() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 90)
        model.setZero()
        model.receiveDemo(degrees: 60)
        #expect(model.relativeDegrees == -30)
        #expect(model.formatted(model.relativeDegrees, signed: true) == "-30.0°")
    }

    @Test func freezeKeepsReadingWhileInputContinues() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 45)
        model.toggleLock()
        model.receiveDemo(degrees: 100)
        #expect(model.shownDegrees == 45)
        #expect(model.liveDegrees == 100)
        model.toggleLock()
        #expect(model.shownDegrees == 100)
    }

    @Test func zeroingWhileFrozenUsesTheFrozenReading() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 45)
        model.toggleLock()
        model.receiveDemo(degrees: 100)
        model.setZero()
        #expect(model.relativeDegrees == 0)
        model.toggleLock()
        #expect(model.relativeDegrees == 55)
    }

    @Test func clearZeroRestoresAbsoluteReading() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 120)
        model.setZero()
        model.clearZero()
        #expect(model.hasZero == false)
        #expect(model.relativeDegrees == model.shownDegrees)
    }

    @Test func inputIsLimitedToPhysicalRange() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 240, state: .hardwareUnknown)
        #expect(model.liveDegrees == 180)
        model.receiveHardware(rawDegrees: -40, state: .hardwareUnknown)
        #expect(model.liveDegrees == 0)
    }

    @Test func nonFiniteInputIsRejected() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 90)
        model.receiveDemo(degrees: .nan)
        model.receiveDemo(degrees: .infinity)
        #expect(model.liveDegrees == 90)
        model.receiveHardware(rawDegrees: .nan, state: .hardwareUnknown)
        #expect(model.liveDegrees == 90)
        #expect(model.hasHardwareHinge == false)
    }

    @Test func demoInputCannotOverrideLiveHardware() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 110, state: .partiallyOpen)
        model.receiveDemo(degrees: 10)
        #expect(model.liveDegrees == 110)
        #expect(model.acceptsDemoInput == false)
    }

    @Test func allHardwareStatesUpdateTheReading() {
        let model = HingeAngleModel()
        for (raw, state) in [(0.0, HingeAngleModel.SourceState.closed),
                             (95.0, .partiallyOpen),
                             (180.0, .fullyOpen)] {
            model.receiveHardware(rawDegrees: raw, state: state)
            #expect(model.liveDegrees == raw)
            #expect(model.sourceState == state)
        }
    }

    @Test func noHingeReportIsDistinctFromDemoAndReopensTheSlider() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 90, state: .partiallyOpen)
        model.reportNoHinge()
        #expect(model.sourceState == .noHinge)
        #expect(model.acceptsDemoInput)
        #expect(model.lastRawHardwareDegrees == nil)
    }

    @Test func rawHardwareValueIsKeptForCalibration() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 200, state: .fullyOpen)
        #expect(model.lastRawHardwareDegrees == 200)
        #expect(model.liveDegrees == 180)
    }

    @Test func hardwareNormalizationIsCentralized() {
        let model = HingeAngleModel()
        #expect(model.normalizeHardwareDegrees(90) == 90)
        #expect(model.normalizeHardwareDegrees(.nan) == 0)
    }

    @Test func autoLockFiresOnlyAfterTheAngleIsHeldStill() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 60, at: 0)
        model.receiveDemo(degrees: 60.1, at: 0.5)
        #expect(model.isLocked == false)
        model.receiveDemo(degrees: 60.1, at: 1.2)
        #expect(model.isLocked)
        #expect(model.lockedAutomatically)
        #expect(model.shownDegrees == 60.1)
    }

    @Test func movementRestartsTheStillnessTimer() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 60, at: 0)
        model.receiveDemo(degrees: 75, at: 0.9)
        model.receiveDemo(degrees: 75, at: 1.5)
        #expect(model.isLocked == false)
        model.receiveDemo(degrees: 75, at: 2.0)
        #expect(model.isLocked)
        #expect(model.shownDegrees == 75)
    }

    @Test func unlockingDoesNotImmediatelyRelock() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 60, at: 0)
        model.receiveDemo(degrees: 60, at: 1.1)
        #expect(model.isLocked)
        model.toggleLock()
        // Still against the corner, so the angle has not moved yet.
        model.receiveDemo(degrees: 60, at: 2.5)
        model.receiveDemo(degrees: 60, at: 4.0)
        #expect(model.isLocked == false)
        // Lift it away and hold somewhere new: locking is allowed again.
        model.receiveDemo(degrees: 100, at: 5.0)
        model.receiveDemo(degrees: 100, at: 6.2)
        #expect(model.isLocked)
        #expect(model.shownDegrees == 100)
    }

    @Test func autoLockCanBeTurnedOff() {
        let model = HingeAngleModel()
        model.autoLockEnabled = false
        model.receiveDemo(degrees: 60, at: 0)
        model.receiveDemo(degrees: 60, at: 5)
        #expect(model.isLocked == false)
    }

    @Test func manualLockIsNotReportedAsAutomatic() {
        let model = HingeAngleModel()
        model.receiveDemo(degrees: 60, at: 0)
        model.toggleLock()
        #expect(model.isLocked)
        #expect(model.lockedAutomatically == false)
    }

    @Test func autoLockAlsoAppliesToHardwareInput() {
        let model = HingeAngleModel()
        model.receiveHardware(rawDegrees: 120, state: .partiallyOpen, at: 0)
        model.receiveHardware(rawDegrees: 120, state: .partiallyOpen, at: 1.1)
        #expect(model.isLocked)
        #expect(model.shownDegrees == 120)
    }

    @Test func radiansConversionMatchesDegrees() {
        let model = HingeAngleModel()
        model.unit = .radians
        model.receiveDemo(degrees: 180)
        #expect(model.formatted(model.shownDegrees) == "3.142 rad")
        model.receiveDemo(degrees: 90)
        #expect(model.formatted(model.shownDegrees) == "1.571 rad")
    }
}
