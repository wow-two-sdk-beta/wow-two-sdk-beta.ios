import Foundation

/// A successful response: the envelope's `data` plus the advisory `warnings` a write raised without failing.
public struct ApiSuccess<T: Sendable>: Sendable {
    public var data: T
    public var warnings: [FieldError]
    public var status: Int

    public init(data: T, warnings: [FieldError] = [], status: Int = 200) {
        self.data = data
        self.warnings = warnings
        self.status = status
    }
}

extension ApiSuccess: Equatable where T: Equatable {}

/// The result of one request — a closed union like the be sdk's `ApiResponse<T>`; branch on it, never catch.
public typealias ApiResult<T: Sendable> = Result<ApiSuccess<T>, ApiFailure>

/// Async JSON client for a be sdk host. It unwraps the `{ data, warnings? }` success envelope into `ApiSuccess`,
/// reads every non-2xx `application/problem+json` body into `ApiFailure.problem`, and never throws.
public struct ApiClient: Sendable {
    public var baseURL: URL
    public var timeout: TimeInterval
    private let transport: any HttpTransport
    private let headers: @Sendable () async -> [String: String]
    private let log: Log?

    /// - Parameters:
    ///   - headers: Read before every request — the place for `Authorization: Bearer …`.
    ///   - log: Receives one line per failure, the URL without its query.
    public init(
        baseURL: URL,
        transport: any HttpTransport = URLSession.shared,
        timeout: TimeInterval = 30,
        headers: @escaping @Sendable () async -> [String: String] = { [:] },
        log: Log? = nil
    ) {
        self.baseURL = baseURL
        self.transport = transport
        self.timeout = timeout
        self.headers = headers
        self.log = log
    }

    /// A client for the build's configured API.
    public init(
        config: AppConfig,
        transport: any HttpTransport = URLSession.shared,
        headers: @escaping @Sendable () async -> [String: String] = { [:] },
        log: Log? = nil
    ) {
        self.init(baseURL: config.apiBaseURL, transport: transport, headers: headers, log: log)
    }

    /// Sends `request` and decodes the success envelope's `data` as `T`.
    public func send<T>(_ request: ApiRequest<T>) async -> ApiResult<T> {
        let label = "\(request.method.rawValue) \(UrlRedaction.path(of: request.path))"
        let urlRequest: URLRequest
        do {
            urlRequest = try await makeURLRequest(request)
        } catch {
            return failure(ApiFailure(code: .transport, request: label, underlying: "\(error)"))
        }

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(urlRequest)
        } catch {
            return failure(Self.transportFailure(error, request: label))
        }

        guard (200..<300).contains(response.statusCode) else {
            let problem = try? ApiJson.decoder().decode(ProblemDetails.self, from: data)
            let isValidation = (response.statusCode == 400 || response.statusCode == 422)
                && !(problem?.errors.isEmpty ?? true)
            return failure(ApiFailure(
                code: isValidation ? .validation : .http,
                status: response.statusCode,
                problem: problem,
                request: label
            ))
        }

        if T.self == NoContent.self, data.isEmpty || response.statusCode == 204 {
            // `T` is `NoContent` here, so the cast always succeeds.
            return .success(ApiSuccess(data: NoContent() as! T, status: response.statusCode))
        }

        do {
            let envelope = try ApiJson.decoder().decode(Envelope<T>.self, from: data)
            return .success(ApiSuccess(data: envelope.data, warnings: envelope.warnings ?? [], status: response.statusCode))
        } catch {
            return failure(ApiFailure(code: .decoding, status: response.statusCode, request: label, underlying: "\(error)"))
        }
    }

    /// Sends `request` and returns the payload alone, throwing the typed failure — for `try await` call sites.
    public func data<T>(_ request: ApiRequest<T>) async throws(ApiFailure) -> T {
        try await send(request).get().data
    }

    func makeURLRequest<T>(_ request: ApiRequest<T>) async throws -> URLRequest {
        // A query written into the path (`/users?page=2`) joins `request.query` instead of being escaped.
        let parts = URLComponents(string: request.path)
        let path = parts?.percentEncodedPath.removingPercentEncoding ?? request.path
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var url = baseURL.appending(path: trimmed, directoryHint: .notDirectory)
        let query = (parts?.queryItems ?? []) + request.query
        if !query.isEmpty { url.append(queryItems: query) }

        var urlRequest = URLRequest(url: url, timeoutInterval: request.timeout ?? timeout)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json, application/problem+json", forHTTPHeaderField: "Accept")
        if let body = request.body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (name, value) in await headers() { urlRequest.setValue(value, forHTTPHeaderField: name) }
        for (name, value) in request.headers { urlRequest.setValue(value, forHTTPHeaderField: name) }
        return urlRequest
    }

    private func failure<T>(_ failure: ApiFailure) -> ApiResult<T> {
        if failure.code != .cancelled {
            log?.warning("\(failure.request) → \(failure.code.rawValue) \(failure.status) \(failure.kind.rawValue)")
        }
        return .failure(failure)
    }

    static func transportFailure(_ error: any Error, request: String) -> ApiFailure {
        if error is CancellationError { return ApiFailure(code: .cancelled, request: request) }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled: return ApiFailure(code: .cancelled, request: request)
            case .timedOut: return ApiFailure(code: .timeout, request: request, underlying: "\(urlError.code)")
            default: break
            }
        }
        return ApiFailure(code: .transport, request: request, underlying: "\(error)")
    }
}

/// The be sdk's success envelope on the wire.
struct Envelope<T: Decodable>: Decodable {
    var data: T
    var warnings: [FieldError]?
}
