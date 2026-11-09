import Foundation

/// What kind of failure a request met — the fe sdk's `ApiFailureCode`.
public enum ApiFailureCode: String, Sendable, Hashable {
    /// The server answered with a non-2xx status.
    case http
    /// No response: offline, DNS, TLS, connection reset.
    case transport
    /// The calling task was cancelled.
    case cancelled
    /// The request timed out.
    case timeout
    /// A 2xx body that is not the expected envelope or payload.
    case decoding
    /// The server rejected the input: a 400 or 422 with field errors.
    case validation
}

/// The failure kind a screen branches on — the be sdk's `AppError` types the status maps to.
public enum ApiFailureKind: String, Sendable, Hashable {
    case unauthorized, forbidden, notFound, conflict, validation, rateLimited, unavailable, cancelled, timeout,
        unexpected
}

/// A display-safe request failure carrying its diagnostics — the be sdk's `ApiResponse<T>.Failure` and the fe
/// sdk's `ApiFailure`.
public struct ApiFailure: Error, Sendable, Hashable, CustomStringConvertible {
    public var code: ApiFailureCode
    public var kind: ApiFailureKind
    /// The HTTP status; `0` when no response arrived.
    public var status: Int
    /// The server's problem body, when it sent one.
    public var problem: ProblemDetails?
    /// The request as `METHOD /path`, query and fragment dropped.
    public var request: String
    /// The underlying transport or decoding error text, for logs only.
    public var underlying: String?

    public init(
        code: ApiFailureCode,
        status: Int = 0,
        problem: ProblemDetails? = nil,
        request: String = "",
        underlying: String? = nil
    ) {
        self.code = code
        self.status = status
        self.problem = problem
        self.request = request
        self.underlying = underlying
        self.kind = Self.kind(code: code, status: status)
    }

    /// The message a screen can show: the server's `detail`, else its `title`, else a generic line per kind.
    public var message: String {
        if let detail = problem?.detail, !detail.isEmpty { return detail }
        if let title = problem?.title, !title.isEmpty { return title }
        return switch kind {
        case .unauthorized: "Please sign in again."
        case .forbidden: "You do not have access to this."
        case .notFound: "This could not be found."
        case .conflict: "This changed elsewhere. Refresh and try again."
        case .validation: "Some fields need attention."
        case .rateLimited: "Too many requests. Try again shortly."
        case .unavailable: "Cannot reach the server. Check your connection."
        case .cancelled: "The request was cancelled."
        case .timeout: "The request timed out."
        case .unexpected: "Something went wrong."
        }
    }

    /// The field failures keyed by property; empty unless the server sent them.
    public var fieldErrors: [String: [FieldError]] { problem?.fieldErrors ?? [:] }

    public var description: String {
        "\(request) failed: \(code.rawValue) \(status) \(underlying ?? message)"
    }

    static func kind(code: ApiFailureCode, status: Int) -> ApiFailureKind {
        switch code {
        case .cancelled: return .cancelled
        case .timeout: return .timeout
        case .transport: return .unavailable
        case .validation: return .validation
        case .decoding: return .unexpected
        case .http: break
        }
        return switch status {
        case 401: .unauthorized
        case 403: .forbidden
        case 404, 410: .notFound
        case 409, 412: .conflict
        case 400, 422: .validation
        case 429: .rateLimited
        case 502, 503, 504: .unavailable
        default: .unexpected
        }
    }
}
