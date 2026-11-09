import Testing
import WoW2IosPresentation

@MainActor
@Suite("ToastCenter")
struct ToastCenterTests {
    @Test func showsFirstAndQueuesTheRest() {
        let center = ToastCenter()
        let first = center.show("One")
        let second = center.show("Two", tone: .success)

        #expect(center.current?.id == first)
        #expect(center.pending.map(\.id) == [second])
    }

    @Test func dismissBringsTheNextForward() {
        let center = ToastCenter()
        center.show("One")
        let second = center.show("Two")

        center.dismiss()

        #expect(center.current?.id == second)
        #expect(center.pending.isEmpty)
        center.dismiss()
        #expect(center.current == nil)
    }

    @Test func dismissingAQueuedToastLeavesTheCurrentOne() {
        let center = ToastCenter()
        let first = center.show("One")
        let second = center.show("Two")
        let third = center.show("Three")

        center.dismiss(second)

        #expect(center.current?.id == first)
        #expect(center.pending.map(\.id) == [third])
    }

    @Test func clearRemovesEverything() {
        let center = ToastCenter()
        center.show("One")
        center.show("Two")

        center.clear()

        #expect(center.current == nil)
        #expect(center.pending.isEmpty)
    }
}
