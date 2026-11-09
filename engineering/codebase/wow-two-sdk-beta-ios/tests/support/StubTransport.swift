import Foundation
import os
import WoW2IosFoundation

/// An `HttpTransport` that answers from a script and records every request — no network in unit tests.
public final class StubTransport: HttpTransport {
    public enum Reply: Sendable {
        case response(status: Int, body: String, headers: [String: String] = [:])
        case failure(URLError.Code)
        case cancelled
    }

    private let state: OSAllocatedUnfairLock<(replies: [Reply], requests: [URLRequest])>

    public init(_ replies: Reply...) {
        state = OSAllocatedUnfairLock(initialState: (replies: replies, requests: []))
    }

    /// One JSON reply.
    public static func json(_ status: Int, _ body: String) -> StubTransport {
        StubTransport(.response(status: status, body: body, headers: ["Content-Type": "application/json"]))
    }

    public var requests: [URLRequest] { state.withLock { $0.requests } }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let reply: Reply = state.withLock { state in
            state.requests.append(request)
            return state.replies.isEmpty ? .response(status: 500, body: "") : state.replies.removeFirst()
        }
        switch reply {
        case .response(let status, let body, let headers):
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
            return (Data(body.utf8), response)
        case .failure(let code):
            throw URLError(code)
        case .cancelled:
            throw CancellationError()
        }
    }
}
