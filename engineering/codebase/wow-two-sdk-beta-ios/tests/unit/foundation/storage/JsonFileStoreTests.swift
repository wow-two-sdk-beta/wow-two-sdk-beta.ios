import Foundation
import Testing
@testable import WoW2IosFoundation

struct JsonFileStoreTests {
    private let defaultValue = [0]
    private let fileName = "plans.json"

    @Test func aValueRoundTrips() async throws {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JsonFileStore(directory: directory, fileName: fileName, defaultValue: defaultValue)
        #expect(try await store.load() == defaultValue)

        try await store.save([1, 2, 3])

        let reopened = JsonFileStore(directory: directory, fileName: fileName, defaultValue: defaultValue)
        #expect(try await reopened.load() == [1, 2, 3])
    }

    @Test func aSaveReplacesTheFileAtomically() async throws {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JsonFileStore(directory: directory, fileName: fileName, defaultValue: defaultValue)
        try await store.save([1])

        let firstRead = try FileHandle(forReadingFrom: directory.appending(path: fileName))
        defer { try? firstRead.close() }
        try await store.save([2, 3])

        let previous = try firstRead.readToEnd()
        let previousBytes = try #require(previous)
        #expect(try JSONDecoder().decode([Int].self, from: previousBytes) == [1])
        #expect(try await store.load() == [2, 3])
    }

    @Test func aCorruptFileIsKeptAsideAndTheDefaultReturned() async throws {
        let directory = makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appending(path: fileName)
        let invalid = Data("not JSON".utf8)
        try invalid.write(to: destination)

        let store = JsonFileStore(directory: directory, fileName: fileName, defaultValue: defaultValue)
        #expect(try await store.load() == defaultValue)

        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let backup = try #require(files.first { $0.lastPathComponent.hasPrefix("\(fileName).corrupt-") })
        #expect(files.count == 2)
        #expect(try Data(contentsOf: backup) == invalid)
        #expect(try JSONDecoder().decode([Int].self, from: Data(contentsOf: destination)) == defaultValue)
    }

    @Test func anInvalidFileNameCannotWriteOutsideItsDirectory() async {
        let directory = makeDirectory()
        let store = JsonFileStore(directory: directory, fileName: "../plans.json", defaultValue: defaultValue)
        await #expect(throws: CocoaError.self) { try await store.save([1]) }
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }
}
