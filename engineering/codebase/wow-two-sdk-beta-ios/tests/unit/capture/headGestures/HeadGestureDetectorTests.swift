import Testing
@testable import WoW2IosCapture

struct HeadGestureDetectorTests {
    @Test func aDipAndReturnInPitchIsANod() {
        #expect(gestures(afterRest: [(0.7, 0.23, 0), (0.8, 0.15, 0), (0.9, 0.05, 0)]) == [.nod])
    }

    @Test func twoOppositeYawSwingsAreAShake() {
        #expect(gestures(afterRest: [(0.7, 0, 0.24), (0.8, 0, 0.02), (1.0, 0, -0.23)]) == [.shake])
    }

    @Test func slowDriftIsNeither() {
        let samples = (7...60).map { index in
            let time = Double(index) / 10
            return (time, 0.03 * time, 0.03 * time)
        }
        #expect(gestures(afterRest: samples).isEmpty)
    }

    @Test func aNodWithLargeYawIsNotANod() {
        #expect(gestures(afterRest: [(0.7, 0.23, 0), (0.8, 0.15, 0.16), (0.9, 0.06, 0.16)]).isEmpty)
    }

    @Test func oneGestureIsReportedOnceThenRests() {
        let samples = [(0.7, 0.23, 0.0), (0.8, 0.04, 0.0), (0.9, 0.25, 0.0), (1.1, 0.0, 0.0),
                       (1.5, 0.0, 0.0), (1.9, 0.0, 0.0), (2.1, 0.25, 0.0), (2.3, 0.02, 0.0)]
        #expect(gestures(afterRest: samples) == [.nod, .nod])
    }

    @Test func theFirstHalfSecondIsIgnored() {
        var detector = HeadGestureDetector()
        let samples = [(0.0, 0.0, 0.0), (0.1, 0.25, 0.0), (0.3, 0.02, 0.0), (0.4, 0.0, 0.0), (0.5, 0.0, 0.0)]
        #expect(samples.compactMap { detector.receive(.init(time: $0.0, pitch: $0.1, yaw: $0.2)) }.isEmpty)
    }

    @Test func aShakeAcrossTheAngleBoundaryIsStillDetected() {
        var detector = HeadGestureDetector()
        for time in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6] {
            #expect(detector.receive(.init(time: time, pitch: 0, yaw: .pi)) == nil)
        }
        #expect(detector.receive(.init(time: 0.7, pitch: 0, yaw: -.pi + 0.25)) == nil)
        #expect(detector.receive(.init(time: 0.9, pitch: 0, yaw: .pi - 0.25)) == .shake)
    }

    private func gestures(afterRest samples: [(Double, Double, Double)]) -> [HeadGesture] {
        var detector = HeadGestureDetector()
        for time in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6] {
            _ = detector.receive(.init(time: time, pitch: 0, yaw: 0))
        }
        return samples.compactMap { detector.receive(.init(time: $0.0, pitch: $0.1, yaw: $0.2)) }
    }
}
