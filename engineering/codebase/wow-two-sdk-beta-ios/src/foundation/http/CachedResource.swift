import Foundation

/// Fetches a typed resource with an ETag and keeps its last validated value in one atomic disk snapshot.
public actor CachedResource<Value: Codable & Sendable> {
    public struct Snapshot: Codable, Sendable {
        public let value: Value
        public let tag: String?
    }

    public enum Failure: Error, Equatable {
        case refreshInProgress
        case missingSnapshot
    }

    private let client: ApiClient
    private let path: String
    private let store: JsonFileStore<Snapshot?>
    private var refreshing = false

    public init(client: ApiClient, path: String, directory: URL, fileName: String) {
        self.client = client
        self.path = path
        self.store = JsonFileStore(directory: directory, fileName: fileName, defaultValue: nil)
    }

    /// Returns the last successful response, including when the server is offline.
    public func current() async throws -> Snapshot? {
        try await store.load()
    }

    /// Validates a changed value and any of its dependencies before publishing a replacement.
    /// On a network, decoding or validation error, callers can keep serving `current()`.
    public func refresh(validate: @Sendable (Value, String?) async throws -> Void = { _, _ in }) async throws -> Snapshot {
        guard !refreshing else { throw Failure.refreshInProgress }
        refreshing = true
        defer { refreshing = false }

        try Task.checkCancellation()
        let previous = try await store.load()
        switch try await client.conditionalGet(path, as: Value.self, previousTag: previous?.tag).get() {
        case .notModified:
            guard let previous else { throw Failure.missingSnapshot }
            return previous
        case .modified(let value, let tag):
            try Task.checkCancellation()
            try await validate(value, tag)
            try Task.checkCancellation()
            let snapshot = Snapshot(value: value, tag: tag)
            try await store.save(snapshot)
            return snapshot
        }
    }
}
