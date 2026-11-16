import Foundation
import Testing
import WoW2IosFoundation
import WoW2IosTestSupport

struct CachedResourceTests {
    @Test func notModifiedReturnsStoredBodyAcrossLaunch() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let transport = StubTransport(
            .response(status: 200, body: "{\"data\":[\"pattern\"]}", headers: ["ETag": "W/\"release-1\""]),
            .response(status: 304, body: "")
        )
        let client = try client(using: transport)
        let first = CachedResource<[String]>(client: client, path: "patterns", directory: directory, fileName: "patterns.json")
        let fresh = try await first.refresh()
        #expect(fresh.tag == "W/\"release-1\"")

        let relaunched = CachedResource<[String]>(client: client, path: "patterns", directory: directory, fileName: "patterns.json")
        let confirmed = try await relaunched.refresh { _, _ in Issue.record("A 304 should not revalidate the body") }
        #expect(confirmed.value == ["pattern"])
        #expect(transport.requests.map { $0.value(forHTTPHeaderField: "If-None-Match") } == [nil, "W/\"release-1\""])
    }

    @Test func rejectedReplacementAndOfflineRefreshKeepTheLastGoodValue() async throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let transport = StubTransport(
            .response(status: 200, body: "{\"data\":[\"good\"]}", headers: ["ETag": "\"a\""]),
            .response(status: 200, body: "{\"data\":[\"bad\"]}", headers: ["ETag": "\"b\""]),
            .failure(.notConnectedToInternet)
        )
        let cache = try CachedResource<[String]>(client: client(using: transport), path: "patterns",
                                                 directory: directory, fileName: "patterns.json")
        _ = try await cache.refresh()
        await #expect(throws: Rejected.self) {
            try await cache.refresh { _, _ in throw Rejected() }
        }
        await #expect(throws: ApiFailure.self) { try await cache.refresh() }
        let snapshot = try #require(try await cache.current())
        #expect(snapshot.value == ["good"])
        #expect(snapshot.tag == "\"a\"")
        #expect(transport.requests.last?.value(forHTTPHeaderField: "If-None-Match") == "\"a\"")
    }

    @Test func unsolicitedNotModifiedIsStillAnHTTPError() async throws {
        let client = try client(using: StubTransport(.response(status: 304, body: "")))
        let result = await client.conditionalGet("patterns", as: [String].self)
        guard case .failure(let error) = result else {
            Issue.record("An unsolicited 304 must be a failure")
            return
        }
        #expect(error.status == 304)
        #expect(error.code == .http)
    }

    private struct Rejected: Error {}

    private func client(using transport: StubTransport) throws -> ApiClient {
        ApiClient(baseURL: try #require(URL(string: "https://example.test/api")), transport: transport)
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
