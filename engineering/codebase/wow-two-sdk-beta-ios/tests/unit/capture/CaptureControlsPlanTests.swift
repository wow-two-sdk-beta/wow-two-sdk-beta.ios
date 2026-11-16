import Testing
@testable import WoW2IosCapture

struct CaptureControlsPlanTests {
    private let countdown = CaptureControlSpec.discreteSlider(id: "countdown", title: "Countdown", symbol: "timer",
                                                               values: [3, 5, 10], selected: 5, valueFormat: "%@ s")
    private let pattern = CaptureControlSpec.indexPicker(id: "pattern", title: "Pattern", symbol: "square.grid.2x2",
                                                        titles: ["Half Heart", "Mirror"], selected: 0)

    @Test func aSessionWithoutControlSupportGetsNone() {
        #expect(CaptureControlsPlan.fitted([.systemZoom, countdown], supportsControls: false, limit: 3, canZoom: true).isEmpty)
    }

    @Test func controlsBeyondTheSessionLimitDropFromTheEnd() {
        #expect(CaptureControlsPlan.fitted([.systemZoom, countdown, pattern], supportsControls: true, limit: 2, canZoom: true)
                == [.systemZoom, countdown])
    }

    @Test func zoomIsSkippedForADeviceThatCannotZoom() {
        #expect(CaptureControlsPlan.fitted([.systemZoom, countdown, pattern], supportsControls: true, limit: 2, canZoom: false)
                == [countdown, pattern])
    }

    @Test func anIdenticalListAndSelectionChangesKeepTheControls() {
        let changedSelection = CaptureControlSpec.indexPicker(id: "pattern", title: "Pattern", symbol: "square.grid.2x2",
                                                               titles: ["Half Heart", "Mirror"], selected: 1)
        #expect(CaptureControlsPlan.definitionsMatch([countdown, pattern], [countdown, pattern]))
        #expect(CaptureControlsPlan.definitionsMatch([countdown, pattern], [countdown, changedSelection]))
        #expect(!CaptureControlsPlan.definitionsMatch([countdown, pattern], [countdown]))
    }
}
