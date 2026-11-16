import Testing
@testable import WoW2IosCapture

@MainActor
struct HardwareShutterEventTests {
    @Test func anEventIsAnAirPodsClickOnlyWhenTheSystemAsksForASound() {
        var events: [HardwareShutterEvent] = []
        var attemptedSounds = 0
        for shouldPlaySound in [false, true] {
            HardwareShutterEvent.dispatch(
                phase: .ended,
                shouldPlaySound: shouldPlaySound,
                onPress: { $0 == .ended },
                playSound: { attemptedSounds += 1; return false },
                onEvent: { events.append($0) }
            )
        }
        #expect(events == [
            HardwareShutterEvent(phase: .ended, isAirPodsClick: false, tookPhoto: true, playedSound: false),
            HardwareShutterEvent(phase: .ended, isAirPodsClick: true, tookPhoto: true, playedSound: false),
        ])
        #expect(attemptedSounds == 1)
    }

    @Test func anIgnoredPressIsStillReported() {
        var reported: HardwareShutterEvent?
        HardwareShutterEvent.dispatch(
            phase: .began,
            shouldPlaySound: true,
            onPress: { $0 == .ended },
            playSound: { Issue.record("An ignored press must not play the shutter sound"); return true },
            onEvent: { reported = $0 }
        )
        #expect(reported == HardwareShutterEvent(
            phase: .began, isAirPodsClick: true, tookPhoto: false, playedSound: false
        ))
    }

    @Test func acceptedAirPodsPressReportsThatTheSystemPlayedTheShutter() {
        var reported: HardwareShutterEvent?
        HardwareShutterEvent.dispatch(
            phase: .ended,
            shouldPlaySound: true,
            onPress: { $0 == .ended },
            playSound: { true },
            onEvent: { reported = $0 }
        )
        #expect(reported?.playedSound == true)
    }
}
