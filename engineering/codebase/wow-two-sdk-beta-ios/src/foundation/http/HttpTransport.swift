import Foundation

/// The seam under `ApiClient`: sends one request and returns the raw response. `URLSession` is the default;
/// tests pass a stub.
public protocol HttpTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
    func upload(_ request: URLRequest, fromFile source: URL) async throws -> (Data, HTTPURLResponse)
}

public extension HttpTransport {
    /// Custom transports opt into file uploads without changing their existing JSON request behavior.
    func upload(_ request: URLRequest, fromFile source: URL) async throws -> (Data, HTTPURLResponse) {
        throw URLError(.unsupportedURL)
    }
}

extension URLSession: HttpTransport {
    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    public func upload(_ request: URLRequest, fromFile source: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await upload(for: request, fromFile: source)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}
