import Testing
import WoW2IosCapture

@Suite("HardwareShutterPolicy")
struct HardwareShutterPolicyTests {
    @Test func theHandlerAttachesOnlyWhileEnabledAndTheCameraRunsOnScreen() {
        #expect(HardwareShutterPolicy.isActive(isEnabled: true, cameraReady: true, screenActive: true))
        // Disabled: volume-down keeps changing the volume.
        #expect(!HardwareShutterPolicy.isActive(isEnabled: false, cameraReady: true, screenActive: true))
        #expect(!HardwareShutterPolicy.isActive(isEnabled: true, cameraReady: false, screenActive: true))
        #expect(!HardwareShutterPolicy.isActive(isEnabled: true, cameraReady: true, screenActive: false))
    }

    @Test func aReleasedPressTakesThePhotoLikeTheOnScreenShutter() {
        #expect(HardwareShutterPolicy.action(for: .ended, cameraReady: true, acceptsPhoto: true, countdownArmed: false) == .capture)
        #expect(HardwareShutterPolicy.action(for: .began, cameraReady: true, acceptsPhoto: true, countdownArmed: false) == .ignore)
        #expect(HardwareShutterPolicy.action(for: .cancelled, cameraReady: true, acceptsPhoto: true, countdownArmed: false) == .ignore)
    }

    @Test func aPressDuringTheArmedCountdownFiresNowAndCancelsTheCountdown() {
        #expect(HardwareShutterPolicy.action(for: .ended, cameraReady: true, acceptsPhoto: true, countdownArmed: true) == .captureCancellingCountdown)
        #expect(HardwareShutterPolicy.action(for: .began, cameraReady: true, acceptsPhoto: true, countdownArmed: true) == .ignore)
    }

    @Test func aBusyOrStoppedCameraIgnoresThePress() {
        #expect(HardwareShutterPolicy.action(for: .ended, cameraReady: true, acceptsPhoto: false, countdownArmed: false) == .ignore)
        #expect(HardwareShutterPolicy.action(for: .ended, cameraReady: true, acceptsPhoto: false, countdownArmed: true) == .ignore)
        #expect(HardwareShutterPolicy.action(for: .ended, cameraReady: false, acceptsPhoto: true, countdownArmed: false) == .ignore)
    }
}
