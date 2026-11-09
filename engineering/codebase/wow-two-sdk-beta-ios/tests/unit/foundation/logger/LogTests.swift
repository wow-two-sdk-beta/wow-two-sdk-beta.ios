import Testing
import WoW2IosFoundation

@Suite("Log")
struct LogTests {
    @Test func writesEveryLevelToSink() {
        let sink = MemoryLogSink()
        let log = Log(category: "shoot", subsystem: "com.wowtwo.test", sink: sink)

        log.debug("d")
        log.info("i")
        log.notice("n")
        log.warning("w")
        log.error("e", privacy: .private)
        log.fault("f")

        #expect(sink.records.map(\.level) == LogLevel.allCases)
        #expect(sink.records.map(\.message) == ["d", "i", "n", "w", "e", "f"])
        #expect(sink.records.allSatisfy { $0.category == "shoot" && $0.subsystem == "com.wowtwo.test" })
    }

    @Test func dropsLevelsBelowMinimum() {
        let sink = MemoryLogSink()
        let log = Log(category: "c", subsystem: "s", minimumLevel: .warning, sink: sink)

        log.debug("hidden")
        log.info("hidden")
        log.warning("shown")

        #expect(sink.records.map(\.message) == ["shown"])
    }

    @Test func keepsOnlyTheNewestRecords() {
        let sink = MemoryLogSink(limit: 2)
        let log = Log(category: "c", subsystem: "s", sink: sink)

        for index in 1...3 { log.info("\(index)") }

        #expect(sink.records.map(\.message) == ["2", "3"])
    }

    @Test(arguments: [
        ("/users?email=a@b.c#top", "/users"),
        ("https://u:p@host.example/x?y=1", "https://host.example/x"),
        ("/plain/path", "/plain/path"),
    ])
    func redactsUrls(_ input: String, _ expected: String) {
        #expect(UrlRedaction.path(of: input) == expected)
    }
}
