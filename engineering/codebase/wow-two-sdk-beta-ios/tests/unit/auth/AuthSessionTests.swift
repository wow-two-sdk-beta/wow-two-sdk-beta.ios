import CryptoKit
import Foundation
import Security
import Testing
@testable import WoW2IosAuth
import WoW2IosFoundation
import WoW2IosTestSupport

@MainActor
struct AuthSessionTests {
    @Test(arguments: LoginFault.allCases)
    func unverifiedTokensNeverReachSignedInState(_ fault: LoginFault) async throws {
        let clock = TestTime()
        let server = TestProvider(clock: clock)
        await server.setFault(fault)
        let store = MemoryTokenStore()
        let session = try makeSession(store: store, server: server, clock: clock)

        await #expect(throws: AuthSessionFailure.invalidResponse) { try await session.signIn(using: browser(server)) }
        #expect(session.state == .signedOut)
        #expect(await session.headers().isEmpty)
        #expect(await store.load() == nil)
    }

    @Test func restoresPreviouslyVerifiedAccountAfterAnOfflineRetry() async throws {
        let clock = TestTime()
        let store = MemoryTokenStore()
        let server = TestProvider(clock: clock)
        let original = try makeSession(store: store, server: server, clock: clock)
        try await original.signIn(using: browser(server))
        #expect(original.state == .signedIn(OidcPrincipal(subject: "person-a", name: "Ada", email: nil, phoneNumber: nil)))
        #expect(await original.headers()["Authorization"] == "Bearer first-access")

        let restored = try makeSession(store: store, server: server, clock: clock)
        await server.setOffline(true)
        await #expect(throws: AuthSessionFailure.unavailable) { try await restored.restore() }
        #expect(restored.state == .signedOut)
        #expect(await store.load()?.accessToken == "first-access")
        await server.setOffline(false)
        try await restored.restore()
        #expect(restored.state == original.state)
        #expect(await restored.validAccessToken() == "first-access")
    }

    @Test func anExpiredSessionRefreshesBeforeRestoreExposesIt() async throws {
        let clock = TestTime()
        let store = MemoryTokenStore()
        let gate = TestGate()
        let server = TestProvider(clock: clock, refreshGate: gate)
        let original = try makeSession(store: store, server: server, clock: clock)
        try await original.signIn(using: browser(server))
        clock.advance(250)

        let restored = try makeSession(store: store, server: server, clock: clock)
        let operation = Task { try await restored.restore() }
        await gate.waitUntilEntered()
        #expect(restored.state == .restoring)
        #expect(await restored.validAccessToken() == nil)
        await gate.release()
        try await operation.value
        #expect(restored.state == original.state)
        #expect(await restored.validAccessToken() == "new-access")
    }

    @Test func overlappingRequestsShareOneRefreshAndSaveTheRotatedToken() async throws {
        let clock = TestTime()
        let store = MemoryTokenStore()
        let gate = TestGate()
        let server = TestProvider(clock: clock, refreshGate: gate)
        let session = try makeSession(store: store, server: server, clock: clock)
        try await session.signIn(using: browser(server))
        clock.advance(121)

        async let one = session.validAccessToken()
        async let two = session.validAccessToken()
        await gate.waitUntilEntered()
        await gate.release()
        let values = await [one, two]
        #expect(values == ["new-access", "new-access"])
        #expect(await server.refreshRequests == 1)
        #expect(await store.load()?.refreshToken == "new-refresh")
        #expect(session.state == .signedIn(OidcPrincipal(subject: "person-a", name: "Ada", email: nil, phoneNumber: nil)))
    }

    @Test func revokingRefreshOrChangingSubjectClearsTheAccount() async throws {
        for mode in [TestProvider.RefreshMode.revoked, .differentSubject] {
            let clock = TestTime()
            let store = MemoryTokenStore()
            let server = TestProvider(clock: clock)
            let session = try makeSession(store: store, server: server, clock: clock)
            try await session.signIn(using: browser(server))
            await server.setRefreshMode(mode)
            clock.advance(121)

            #expect(await session.validAccessToken() == nil)
            #expect(await store.load() == nil)
            #expect(session.state == .signedOut)
            #expect(session.lastFailure == .signedOutByProvider)
        }
    }

    @Test func aLateNetworkRefreshCannotUndoSignOut() async throws {
        let clock = TestTime()
        let store = MemoryTokenStore()
        let gate = TestGate()
        let server = TestProvider(clock: clock, refreshGate: gate)
        let session = try makeSession(store: store, server: server, clock: clock)
        try await session.signIn(using: browser(server))
        clock.advance(121)

        let request = Task { await session.validAccessToken() }
        await gate.waitUntilEntered()
        try await session.signOut()
        await gate.release()
        #expect(await request.value == nil)
        #expect(await store.load() == nil)
        #expect(session.state == .signedOut)
    }

    @Test func signOutRemovesCredentialsAfterAnAlreadyQueuedSave() async throws {
        let clock = TestTime()
        let gate = TestGate()
        let store = PausedTokenStore(gate: gate)
        let server = TestProvider(clock: clock)
        let session = try makeSession(store: store, server: server, clock: clock)
        try await session.signIn(using: browser(server))
        clock.advance(121)

        let request = Task { await session.validAccessToken() }
        await gate.waitUntilEntered()
        let signOut = Task { try await session.signOut() }
        while session.state != .signedOut { await Task.yield() }
        await gate.release()
        try await signOut.value
        #expect(await request.value == nil)
        #expect(await store.load() == nil)
    }

    @Test func aCancelledBrowserLeavesNoFailureOrTokenExchange() async throws {
        let clock = TestTime()
        let store = MemoryTokenStore()
        let server = TestProvider(clock: clock)
        let session = try makeSession(store: store, server: server, clock: clock)

        try await session.signIn { _, _ in throw CancellationError() }
        #expect(session.state == .signedOut)
        #expect(session.lastFailure == nil)
        #expect(await server.loginRequests == 0)
        #expect(await store.load() == nil)
    }

    private func makeSession(store: any TokenStore, server: TestProvider, clock: TestTime) throws -> AuthSession {
        let config = try OidcClientConfiguration(authority: TestProvider.issuer, clientID: TestProvider.client,
                                                 redirectURI: URL(string: "com.example.app:/signin")!)
        return AuthSession(configuration: config, store: store, transport: server, time: clock.now)
    }

    private func browser(_ server: TestProvider) -> AuthSession.Browser {
        { url, scheme in
            let parts = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let state = try #require(parts.queryItems?.first { $0.name == "state" }?.value)
            let nonce = try #require(parts.queryItems?.first { $0.name == "nonce" }?.value)
            await server.setNonce(nonce)
            return URL(string: "\(scheme):/signin?code=some-code&state=\(state)")!
        }
    }
}

enum LoginFault: CaseIterable, Sendable {
    case issuer, audience, nonce, signature, expired, hash, algorithm, missingIDToken
}

private final class TestTime: @unchecked Sendable {
    private let lock = NSLock()
    private var date = Date(timeIntervalSince1970: 1_800_000_000)

    func now() -> Date { lock.withLock { date } }
    func advance(_ interval: TimeInterval) { lock.withLock { date = date.addingTimeInterval(interval) } }
}

private actor TestGate {
    private var started = false
    private var released = false
    private var observers: [CheckedContinuation<Void, Never>] = []
    private var paused: CheckedContinuation<Void, Never>?

    func waitUntilEntered() async {
        if !started { await withCheckedContinuation { observers.append($0) } }
    }

    func enter() async {
        started = true
        observers.forEach { $0.resume() }
        observers.removeAll()
        if !released { await withCheckedContinuation { paused = $0 } }
    }

    func release() {
        released = true
        paused?.resume()
        paused = nil
    }
}

private actor PausedTokenStore: TokenStore {
    private let gate: TestGate
    private var tokens: OidcTokens?

    init(gate: TestGate) { self.gate = gate }
    func load() -> OidcTokens? { tokens }
    func save(_ value: OidcTokens) async {
        if value.accessToken == "new-access" { await gate.enter() }
        tokens = value
    }
    func remove() { tokens = nil }
}

private actor TestProvider: HttpTransport {
    enum RefreshMode: Equatable { case valid, revoked, differentSubject }
    static let issuer = URL(string: "https://identity.example.test/")!
    static let client = "example-native"
    private let clock: TestTime
    private let signingKey = P256.Signing.PrivateKey()
    private let refreshGate: TestGate?
    private var nonce: String?
    private var fault: LoginFault?
    private var refreshMode: RefreshMode = .valid
    private var offline = false
    private(set) var refreshRequests = 0
    private(set) var loginRequests = 0

    init(clock: TestTime, refreshGate: TestGate? = nil) {
        self.clock = clock
        self.refreshGate = refreshGate
    }

    func setNonce(_ nonce: String) { self.nonce = nonce }
    func setFault(_ fault: LoginFault) { self.fault = fault }
    func setRefreshMode(_ mode: RefreshMode) { self.refreshMode = mode }
    func setOffline(_ value: Bool) { offline = value }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if offline { throw URLError(.notConnectedToInternet) }
        let url = try #require(request.url)
        switch url.path {
        case "/.well-known/openid-configuration":
            let host = Self.issuer.absoluteString
            return try response(url, json: [
                "issuer": host, "authorization_endpoint": host + "authorize", "token_endpoint": host + "token",
                "jwks_uri": host + "keys", "id_token_signing_alg_values_supported": ["ES256"],
            ])
        case "/keys":
            let key = signingKey.publicKey.x963Representation
            return try response(url, json: ["keys": [[
                "kty": "EC", "kid": "key", "alg": "ES256", "use": "sig", "crv": "P-256",
                "x": Base64URL.encode(Data(key[1..<33])), "y": Base64URL.encode(Data(key[33..<65])),
            ]]])
        case "/token":
            let grant = request.httpBody.map { String(decoding: $0, as: UTF8.self) } ?? ""
            if grant.contains("grant_type=refresh_token") {
                refreshRequests += 1
                if let refreshGate { await refreshGate.enter() }
                if refreshMode == .revoked { return try response(url, status: 400, json: ["error": "invalid_grant"]) }
                let updated = refreshMode == .differentSubject
                    ? try idToken(accessToken: "new-access", subject: "person-b", nonce: nil, fault: nil) : nil
                return try reply(url, access: "new-access", refresh: "new-refresh", id: updated)
            }
            loginRequests += 1
            let id = fault == .missingIDToken
                ? nil : try idToken(accessToken: "first-access", subject: "person-a", nonce: nonce, fault: fault)
            return try reply(url, access: "first-access", refresh: "first-refresh", id: id)
        default:
            throw URLError(.unsupportedURL)
        }
    }

    private func reply(_ url: URL, access: String, refresh: String, id: String?) throws -> (Data, HTTPURLResponse) {
        var object: [String: Any] = [
            "access_token": access, "expires_in": 120, "token_type": "Bearer", "refresh_token": refresh,
        ]
        object["id_token"] = id
        return try response(url, json: object)
    }

    private func response(_ url: URL, status: Int = 200, json: [String: Any]) throws -> (Data, HTTPURLResponse) {
        let data = try JSONSerialization.data(withJSONObject: json)
        return (data, HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }

    private func idToken(accessToken: String, subject: String, nonce: String?, fault: LoginFault?) throws -> String {
        let now = clock.now().timeIntervalSince1970
        let header = try JSONSerialization.data(withJSONObject: [
            "alg": fault == .algorithm ? "none" : "ES256", "kid": "key", "typ": "JWT",
        ])
        var claims: [String: Any] = [
            "iss": fault == .issuer ? "https://other.example.test/" : Self.issuer.absoluteString,
            "aud": fault == .audience ? [Self.client, "other"] : [Self.client],
            "sub": subject, "name": "Ada", "iat": fault == .expired ? now - 1000 : now, "exp": fault == .expired ? now - 120 : now + 120,
            "at_hash": fault == .hash ? "wrong" : Base64URL.encode(Data(SHA256.hash(data: Data(accessToken.utf8)).prefix(16))),
        ]
        claims["nonce"] = fault == .nonce ? "wrong" : nonce
        let payload = try JSONSerialization.data(withJSONObject: claims)
        let message = "\(Base64URL.encode(header)).\(Base64URL.encode(payload))"
        let key = fault == .signature ? P256.Signing.PrivateKey() : signingKey
        let proof = try key.signature(for: Data(message.utf8)).rawRepresentation
        return "\(message).\(Base64URL.encode(proof))"
    }
}
