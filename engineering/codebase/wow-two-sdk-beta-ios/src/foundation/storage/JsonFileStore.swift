import Foundation

/// Stores a single Codable value in a file. Use one instance per file to serialize related operations.
public actor JsonFileStore<Value: Codable & Sendable> {
    private let directory: URL
    private let fileName: String
    private let defaultValue: Value

    public init(directory: URL, fileName: String, defaultValue: Value) {
        self.directory = directory
        self.fileName = fileName
        self.defaultValue = defaultValue
    }

    /// A missing file returns the default. Unreadable JSON is preserved beside the original file, then
    /// replaced with the default. Other filesystem errors propagate.
    public func load() throws -> Value {
        let destination = try fileURL()
        let bytes: Data
        do {
            bytes = try Data(contentsOf: destination)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            return defaultValue
        }

        do {
            return try JSONDecoder().decode(Value.self, from: bytes)
        } catch {
            // Encode before moving aside the only existing copy.
            let replacement = try JSONEncoder().encode(defaultValue)
            let backup = directory.appending(path: "\(fileName).corrupt-\(UUID().uuidString)", directoryHint: .notDirectory)
            try FileManager.default.moveItem(at: destination, to: backup)
            try replacement.write(to: destination, options: .atomic)
            return defaultValue
        }
    }

    /// Encodes before touching the existing file and publishes the replacement in one atomic write.
    public func save(_ value: Value) throws {
        let destination = try fileURL()
        let bytes = try JSONEncoder().encode(value)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try bytes.write(to: destination, options: .atomic)
    }

    private func fileURL() throws -> URL {
        guard directory.isFileURL, !fileName.isEmpty, fileName != ".", fileName != "..",
              !fileName.contains("/"), !fileName.contains("\0") else {
            throw CocoaError(.fileReadInvalidFileName)
        }
        return directory.appending(path: fileName, directoryHint: .notDirectory)
    }
}
