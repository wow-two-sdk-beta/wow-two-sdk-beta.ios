import Foundation
import Testing
import WoW2IosFoundation
import WoW2IosTestSupport

private struct UserDto: Codable, Sendable, Equatable {
    var id: String
    var name: String
    var createdAt: Date?
}

private struct RenameUser: Encodable {
    var name: String
}

private let baseURL = URL(string: "https://api.example.com/v1")!

@Suite("ApiClient")
struct ApiClientTests {
    @Test func unwrapsSuccessEnvelope() async throws {
        let transport = StubTransport.json(200, #"{"data":{"id":"u1","name":"Ada"}}"#)
        let client = ApiClient(baseURL: baseURL, transport: transport)

        let success = try await client.send(.get("/users/u1", as: UserDto.self)).get()

        #expect(success.data == UserDto(id: "u1", name: "Ada"))
        #expect(success.warnings.isEmpty)
        #expect(success.status == 200)
    }

    @Test func carriesWarnings() async throws {
        let body = #"""
        {"data":{"id":"u1","name":"Ada"},
         "warnings":[{"property":"Name","message":"Short name","code":"MinimumLengthValidator",
                      "params":{"MinLength":3},"severity":"warning"}]}
        """#
        let client = ApiClient(baseURL: baseURL, transport: StubTransport.json(200, body))

        let success = try await client.send(.get("/users/u1", as: UserDto.self)).get()

        #expect(success.warnings.count == 1)
        #expect(success.warnings[0].severity == .warning)
        #expect(success.warnings[0].params?["MinLength"] == .number(3))
    }

    @Test(arguments: [
        "2026-11-09T12:00:00.1234567+00:00",
        "2026-11-09T12:00:00.123Z",
        "2026-11-09T12:00:00Z",
        "2026-11-09T17:00:00+05:00",
    ])
    func decodesDotNetDates(_ text: String) async throws {
        let body = #"{"data":{"id":"u1","name":"Ada","createdAt":"\#(text)"}}"#
        let client = ApiClient(baseURL: baseURL, transport: StubTransport.json(200, body))

        let user = try await client.data(.get("/users/u1", as: UserDto.self))

        let expected = Date(timeIntervalSince1970: 1_794_225_600)
        #expect(abs(try #require(user.createdAt).timeIntervalSince(expected)) < 1)
    }

    @Test func buildsRequestFromBaseURLPathQueryAndHeaders() async throws {
        let transport = StubTransport.json(200, #"{"data":{"id":"u1","name":"Ada"}}"#)
        let client = ApiClient(baseURL: baseURL, transport: transport, headers: { ["Authorization": "Bearer t0k"] })

        _ = await client.send(.get("users", query: [URLQueryItem(name: "q", value: "a b")], as: UserDto.self))

        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.example.com/v1/users?q=a%20b")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer t0k")
        #expect(request.value(forHTTPHeaderField: "Accept")?.contains("application/problem+json") == true)
    }

    @Test func mergesQueryWrittenIntoPath() async throws {
        let transport = StubTransport.json(200, #"{"data":{"id":"u1","name":"Ada"}}"#)
        let client = ApiClient(baseURL: baseURL, transport: transport)

        _ = await client.send(.get("/users?page=2", query: [URLQueryItem(name: "size", value: "20")], as: UserDto.self))

        let request = try #require(transport.requests.first)
        #expect(request.url?.absoluteString == "https://api.example.com/v1/users?page=2&size=20")
    }

    @Test func encodesJsonBody() async throws {
        let transport = StubTransport.json(200, #"{"data":{"id":"u1","name":"Grace"}}"#)
        let client = ApiClient(baseURL: baseURL, transport: transport)

        _ = await client.send(try .patch("/users/u1", body: RenameUser(name: "Grace"), as: UserDto.self))

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody.flatMap { String(data: $0, encoding: .utf8) } == #"{"name":"Grace"}"#)
    }

    @Test func acceptsNoContent() async throws {
        let transport = StubTransport(.response(status: 204, body: ""))
        let client = ApiClient(baseURL: baseURL, transport: transport)

        let success = try await client.send(.delete("/users/u1", as: NoContent.self)).get()

        #expect(success.status == 204)
    }

    @Test func readsValidationProblemWithWowTwoErrors() async {
        let body = #"""
        {"type":"urn:wow-two:error:Validation","status":422,"detail":"Validation failed","code":"Validation",
         "traceId":"00-abc","errors":[{"property":"Name","message":"Name is required.","code":"NotEmptyValidator"},
                                       {"property":"Name","message":"Too short.","code":"MinimumLengthValidator"}]}
        """#
        let client = ApiClient(baseURL: baseURL, transport: StubTransport.json(422, body))

        let result = await client.send(.get("/users", as: UserDto.self))

        guard case .failure(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure.code == .validation)
        #expect(failure.kind == .validation)
        #expect(failure.status == 422)
        #expect(failure.message == "Validation failed")
        #expect(failure.problem?.traceId == "00-abc")
        #expect(failure.fieldErrors["Name"]?.map(\.code) == ["NotEmptyValidator", "MinimumLengthValidator"])
    }

    @Test func readsAspNetErrorDictionary() async {
        let body = #"{"title":"One or more validation errors occurred.","status":400,"errors":{"Email":["Invalid email."]}}"#
        let client = ApiClient(baseURL: baseURL, transport: StubTransport.json(400, body))

        let result = await client.send(.get("/users", as: UserDto.self))

        guard case .failure(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure.code == .validation)
        #expect(failure.fieldErrors["Email"]?.first?.message == "Invalid email.")
        #expect(failure.message == "One or more validation errors occurred.")
    }

    @Test(arguments: [(401, ApiFailureKind.unauthorized), (403, .forbidden), (404, .notFound), (409, .conflict),
                      (429, .rateLimited), (503, .unavailable), (500, .unexpected)])
    func mapsStatusToKind(_ status: Int, _ kind: ApiFailureKind) async {
        let client = ApiClient(baseURL: baseURL, transport: StubTransport(.response(status: status, body: "<html>")))

        let result = await client.send(.get("/x", as: NoContent.self))

        guard case .failure(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure.code == .http)
        #expect(failure.kind == kind)
        #expect(failure.problem == nil)
        #expect(!failure.message.isEmpty)
    }

    @Test func reportsMalformedEnvelopeAsDecoding() async {
        let client = ApiClient(baseURL: baseURL, transport: StubTransport.json(200, #"{"id":"u1"}"#))

        let result = await client.send(.get("/users/u1", as: UserDto.self))

        guard case .failure(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure.code == .decoding)
        #expect(failure.underlying != nil)
    }

    @Test(arguments: [
        (StubTransport.Reply.failure(.notConnectedToInternet), ApiFailureCode.transport),
        (.failure(.timedOut), .timeout),
        (.failure(.cancelled), .cancelled),
        (.cancelled, .cancelled),
    ])
    func mapsTransportErrors(_ reply: StubTransport.Reply, _ code: ApiFailureCode) async {
        let client = ApiClient(baseURL: baseURL, transport: StubTransport(reply))

        let result = await client.send(.get("/x", as: NoContent.self))

        guard case .failure(let failure) = result else { Issue.record("expected failure"); return }
        #expect(failure.code == code)
        #expect(failure.status == 0)
    }

    @Test func throwsTypedFailureFromData() async {
        let client = ApiClient(baseURL: baseURL, transport: StubTransport(.response(status: 404, body: "")))

        await #expect(throws: ApiFailure.self) {
            _ = try await client.data(.get("/users/missing", as: UserDto.self))
        }
    }

    @Test func logsFailureWithoutQuery() async {
        let sink = MemoryLogSink()
        let log = Log(category: "api", subsystem: "test", sink: sink)
        let client = ApiClient(baseURL: baseURL, transport: StubTransport(.response(status: 404, body: "")), log: log)

        _ = await client.send(.get("/users?email=ada@example.com", as: UserDto.self))

        let line = sink.records.first?.message ?? ""
        #expect(line.contains("GET /users"))
        #expect(!line.contains("ada@example.com"))
        #expect(sink.records.first?.level == .warning)
    }
}
