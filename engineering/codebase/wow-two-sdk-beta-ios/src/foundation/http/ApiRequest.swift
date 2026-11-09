import Foundation

/// An HTTP method.
public struct HttpMethod: RawRepresentable, Sendable, Hashable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue.uppercased() }

    public static let get = HttpMethod(rawValue: "GET")
    public static let post = HttpMethod(rawValue: "POST")
    public static let put = HttpMethod(rawValue: "PUT")
    public static let patch = HttpMethod(rawValue: "PATCH")
    public static let delete = HttpMethod(rawValue: "DELETE")
}

/// A typed request: the response payload type rides in `Response`, so `client.send(.get("/me", as: UserDto.self))`
/// returns `ApiResult<UserDto>`.
public struct ApiRequest<Response: Decodable & Sendable>: Sendable {
    public var method: HttpMethod
    /// The path relative to the client's base URL, with or without a leading slash.
    public var path: String
    public var query: [URLQueryItem]
    public var headers: [String: String]
    /// The JSON-encoded body; `nil` sends none.
    public var body: Data?
    /// Overrides the client's timeout for this request.
    public var timeout: TimeInterval?

    public init(
        method: HttpMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }

    public static func get(_ path: String, query: [URLQueryItem] = [], as _: Response.Type = Response.self) -> Self {
        Self(method: .get, path: path, query: query)
    }

    public static func delete(_ path: String, as _: Response.Type = Response.self) -> Self {
        Self(method: .delete, path: path)
    }

    /// A request carrying `body` as JSON, encoded with the be sdk's conventions (`ApiJson.encoder`).
    public static func send(
        _ method: HttpMethod,
        _ path: String,
        body: some Encodable,
        as _: Response.Type = Response.self
    ) throws -> Self {
        Self(method: method, path: path, body: try ApiJson.encoder().encode(body))
    }

    public static func post(_ path: String, body: some Encodable, as type: Response.Type = Response.self) throws -> Self {
        try send(.post, path, body: body, as: type)
    }

    public static func put(_ path: String, body: some Encodable, as type: Response.Type = Response.self) throws -> Self {
        try send(.put, path, body: body, as: type)
    }

    public static func patch(_ path: String, body: some Encodable, as type: Response.Type = Response.self) throws -> Self {
        try send(.patch, path, body: body, as: type)
    }
}

/// The payload type of an endpoint that answers `204 No Content` or an envelope with no meaningful data.
public struct NoContent: Decodable, Sendable, Hashable {
    public init() {}
}
